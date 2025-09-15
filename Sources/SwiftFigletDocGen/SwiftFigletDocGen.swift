import ArgumentParser
import Foundation
import SwiftFigletKit

@main
struct SwiftFigletDocGen: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swift-figlet-doc-gen",
    abstract: "Generate a DocC Fonts Gallery article for SwiftFigletKit"
  )

  @Option(
    name: .customLong("output"),
    help: "Output Markdown path for FontsGallery.md"
  )
  var outputPath: String

  @Option(
    name: .customLong("text"),
    help: "Sample text to render for each font (default: Figlet)"
  )
  var sampleText: String = "Figlet"

  @Flag(
    name: .customLong("deduplicate"),
    help: "Collapse duplicate fonts (identical .flf content)"
  )
  var deduplicate: Bool = false

  @Option(
    name: .customLong("aliases-report"),
    help:
      "Optional path to write a JSON alias report (groups of identical fonts)"
  )
  var aliasesReportPath: String?

  @Option(
    name: .customLong("emit-delete-plan"),
    help:
      "Optional path to write a JSON delete plan with {hash, keepFile, deleteFiles}"
  )
  var emitDeletePlanPath: String?

  mutating func run() throws {
    let fm = FileManager.default
    let outURL = URL(fileURLWithPath: outputPath)

    // Ensure parent directory exists
    try fm.createDirectory(
      at: outURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )

    // Collect fonts
    let urls = SFKFonts.all().sorted {
      $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent)
        == .orderedAscending
    }

    struct Entry {
      let name: String
      let url: URL
    }
    var entries: [Entry] = urls.map {
      .init(name: $0.deletingPathExtension().lastPathComponent, url: $0)
    }

    // Optional deduplication by file content after normalizing line endings
    // Build hash groups for duplicates
    var hashGroups: [UInt64: [Entry]] = [:]
    for e in entries {
      guard let data = try? Data(contentsOf: e.url) else { continue }
      let normalized = normalizeLineEndings(data: data)
      let h = fnv1a64(data: normalized)
      hashGroups[h, default: []].append(e)
    }
    if deduplicate {
      entries = hashGroups.keys
        .sorted { $0 < $1 }
        .compactMap { hashGroups[$0]?.first }
    }

    var md = ""  // Markdown buffer
    md += "# Fonts Gallery\n\n"
    md += "This page is generated. Sample text: `\(sampleText)`\n\n"

    for e in entries {
      md += "## \(e.name)\n\n"
      if let reported = extractInFileName(from: e.url), !reported.isEmpty, reported != e.name {
        md += "Reported name: \(reported)\n\n"
      }
      md += "```\n"
      if let rendered = SFKRenderer.render(text: sampleText, fontName: e.name) {
        md += rendered
      } else {
        md += "(render failed)\n"
      }
      md += "```\n\n"
    }

    // Write gallery atomically
    try md.write(to: outURL, atomically: true, encoding: .utf8)

    // Optional aliases report
    if let path = aliasesReportPath {
      let reportURL = URL(fileURLWithPath: path)
      let enc = JSONEncoder()
      enc.outputFormatting = [.prettyPrinted, .sortedKeys]
      struct Group: Codable {
        let hash: String
        let names: [String]
        let files: [String]
      }
      let groups: [Group] =
        hashGroups
        .filter { $0.value.count > 1 }
        .map { (k, v) in
          Group(
            hash: String(format: "%016llx", k),
            names: v.map { $0.name }.sorted {
              $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            },
            files: v.map { $0.url.lastPathComponent }.sorted {
              $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }
          )
        }
        .sorted { $0.hash < $1.hash }
      try enc.encode(groups).write(to: reportURL)
    }

    // Optional delete plan
    if let path = emitDeletePlanPath {
      let out = URL(fileURLWithPath: path)
      let enc = JSONEncoder()
      enc.outputFormatting = [.prettyPrinted, .sortedKeys]
      struct DeletePlan: Codable {
        let hash: String
        let keepFile: String
        let deleteFiles: [String]
      }
      var plans: [DeletePlan] = []
      for (k, entries) in hashGroups.sorted(by: { $0.key < $1.key }) where entries.count > 1 {
        let files = entries.map { $0.url.lastPathComponent }
        let keep = choosePreferred(files: files)
        let deletes =
          files
          .filter { $0 != keep }
          .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        plans.append(
          .init(hash: String(format: "%016llx", k), keepFile: keep, deleteFiles: deletes))
      }
      try enc.encode(plans).write(to: out)
    }
  }

  // Prefer spaced/proper-cased names, then hyphen over underscore, then longest filename
  private func choosePreferred(files: [String]) -> String {
    var bestFile = ""
    var bestScore = Int.min
    let uppercase = CharacterSet.uppercaseLetters
    for f in files {
      var score = 0
      if f.contains(" ") { score += 100 }
      if f.rangeOfCharacter(from: uppercase) != nil { score += 20 }
      if f.contains("-") { score += 5 }
      score += f.count / 10
      if score > bestScore {
        bestScore = score
        bestFile = f
      }
    }
    return bestFile
  }

  // Normalize CRLF/CR to LF
  private func normalizeLineEndings(data: Data) -> Data {
    guard
      let s = String(data: data, encoding: .utf8)
        ?? String(data: data, encoding: .isoLatin1)
    else { return data }
    let normalized =
      s
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
    return Data(normalized.utf8)
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

  // Heuristic extractor for human-readable font name from comment lines
  private func extractInFileName(from url: URL) -> String? {
    guard
      let text = (try? String(contentsOf: url, encoding: .utf8))
        ?? (try? String(contentsOf: url, encoding: .isoLatin1))
    else { return nil }
    let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
      of: "\r", with: "\n")
    guard
      let firstLine = normalized.split(
        separator: "\n", maxSplits: 1, omittingEmptySubsequences: false
      ).first
    else { return nil }
    let parts = firstLine.split(separator: " ")
    let commentCount: Int = (parts.count > 5) ? Int(parts[5]) ?? 0 : 0
    guard commentCount > 0 else { return nil }
    let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
    let start = 1
    let end = min(lines.count, 1 + commentCount)
    if start >= end { return nil }
    let comments = lines[start..<end].map { String($0) }

    // Regex-like checks using String operations (avoid NSRegularExpression for simplicity)
    func match(prefixes: [String], in s: String) -> String? {
      let lower = s.trimmingCharacters(in: .whitespaces)
      for p in prefixes where lower.lowercased().hasPrefix(p) {
        let value = String(lower.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
        if !value.isEmpty, !value.lowercased().contains("version"),
          !value.lowercased().contains("author"), !value.lowercased().contains("date")
        {
          return value
        }
      }
      return nil
    }

    for c in comments {
      if let v = match(
        prefixes: [
          "font name:", "font:", "figlet font:", "figletfont:", "font-name:", "font=",
          "font name =", "font:",
        ], in: c)
      {
        return v
      }
    }
    for c in comments {
      if let v = match(
        prefixes: ["name:", "title:", "name =", "title =", "name-", "title-"], in: c)
      {
        return v
      }
    }
    // Fallback: first non-empty that doesn't look like metadata
    for c in comments {
      let t = c.trimmingCharacters(in: .whitespaces)
      if t.isEmpty { continue }
      let l = t.lowercased()
      if l.contains("http") || l.contains("www.") || l.contains("copyright") || l.contains("author")
        || l.contains("version") || l.contains("date")
      {
        continue
      }
      return t
    }
    return nil
  }
}
