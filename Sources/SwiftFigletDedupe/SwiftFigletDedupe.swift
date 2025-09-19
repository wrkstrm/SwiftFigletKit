import ArgumentParser
import Foundation
import SwiftFigletKit

@main
struct SwiftFigletDedupe: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swift-figlet-dedupe",
    abstract:
      "Move duplicate font variants (spaces/uppercase names) to docs/Fonts/duplicates, keeping a simple canonical file per group",
  )

  @Option(
    name: .customLong("root"),
    help: "Path to Fonts directory (default: ./Sources/SwiftFigletKit/Resources/Fonts)",
  )
  var rootPath: String?

  @Option(
    name: .customLong("dest"),
    help: "Destination directory for moved duplicates (default: docs/Fonts/duplicates)",
  )
  var destPath: String = "docs/Fonts/duplicates"

  @Flag(name: .customLong("apply"), help: "Apply moves (otherwise dry-run)")
  var apply: Bool = false

  mutating func run() async throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let defaultRoot =
      cwd
      .appendingPathComponent("Sources/SwiftFigletKit/Resources/Fonts", isDirectory: true)
    let root = URL(fileURLWithPath: rootPath ?? defaultRoot.path, isDirectory: true)
    let dest = URL(fileURLWithPath: destPath, isDirectory: true, relativeTo: cwd)

    guard
      let items = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        .filter({ $0.pathExtension.lowercased() == "flf" })
    else {
      throw ValidationError("Unable to list fonts at \(root.path)")
    }

    struct Entry {
      let url: URL
      let name: String  // filename without extension
    }
    var entries: [Entry] = items.map {
      .init(url: $0, name: $0.deletingPathExtension().lastPathComponent)
    }

    // Group by content hash (normalized newlines, UTF-8/Latin-1 decode)
    var groups: [UInt64: [Entry]] = [:]
    for e in entries {
      guard let data = try? Data(contentsOf: e.url) else { continue }
      let norm = normalizeLineEndings(data: data)
      let h = fnv1a64(data: norm)
      groups[h, default: []].append(e)
    }

    var plannedMoves: [(from: URL, to: URL)] = []
    for (_, g) in groups where g.count > 1 {
      // choose simplest to keep (no spaces, lowercase, shortest)
      let keep = chooseSimplest(files: g.map(\.url.lastPathComponent))
      for e in g {
        let file = e.url.lastPathComponent
        if file == keep { continue }
        // Only move duplicates that are "complicated" (contain spaces or uppercase)
        let hasSpaces = file.contains(" ")
        let hasUpper = file.rangeOfCharacter(from: .uppercaseLetters) != nil
        if hasSpaces || hasUpper {
          let to = dest.appendingPathComponent(file)
          plannedMoves.append((from: e.url, to: to))
        }
      }
    }

    if plannedMoves.isEmpty {
      print("No duplicate variants to move.")
      return
    }

    if !apply {
      print("Dry-run. Planned moves (\(plannedMoves.count)):")
      for m in plannedMoves {
        print("MV \(m.from.path) -> \(m.to.path)")
      }
      return
    }

    try fm.createDirectory(at: dest, withIntermediateDirectories: true)
    for m in plannedMoves {
      try fm.createDirectory(
        at: m.to.deletingLastPathComponent(), withIntermediateDirectories: true,
      )
      // Move (overwrite if exists)
      if fm.fileExists(atPath: m.to.path) { try fm.removeItem(at: m.to) }
      try fm.moveItem(at: m.from, to: m.to)
      print("Moved \(m.from.lastPathComponent) -> \(m.to.path)")
    }
  }

  private func chooseSimplest(files: [String]) -> String {
    var best = files.first ?? ""
    var bestScore = Int.max
    for f in files {
      var score = 0
      if f.contains(" ") { score += 100 }
      if f.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 50 }
      if f.contains("-") { score += 5 }
      if f.contains("_") { score += 2 }
      score += f.count
      if score < bestScore {
        best = f
        bestScore = score
      }
    }
    return best
  }

  private func normalizeLineEndings(data: Data) -> Data {
    if let s = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) {
      let n = s.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
        of: "\r", with: "\n",
      )
      return Data(n.utf8)
    }
    return data
  }

  private func fnv1a64(data: Data) -> UInt64 {
    let prime: UInt64 = 1_099_511_628_211
    var hash: UInt64 = 1_469_598_103_934_665_603
    for b in data {
      hash ^= UInt64(b)
      hash &*= prime
    }
    return hash
  }
}
