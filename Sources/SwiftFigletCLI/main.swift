import ArgumentParser
import Foundation
import SwiftFigletKit

@main
struct SwiftFigletCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swift-figlet-cli",
    abstract: "Render text using bundled FIGlet fonts"
  )

  @Flag(name: .customLong("list-fonts"), help: "List bundled fonts and exit")
  var listFonts: Bool = false

  @Flag(name: .customLong("random-font"), help: "Print a random bundled font name and exit")
  var randomFontOnly: Bool = false

  @Option(name: .customLong("font"), help: "Font to use (base name, 'random', or .flf)")
  var fontName: String?

  @Argument(help: "Text to render. If omitted, reads from stdin when piped.")
  var text: [String] = []

  func run() throws {
    if listFonts {
      let names = SFKFonts.listNames()
      if names.isEmpty { throw ValidationError("No bundled fonts found.") }
      names.forEach { print($0) }
      return
    }

    if randomFontOnly {
      guard let name = SFKFonts.randomName() else {
        throw ValidationError("No bundled fonts found.")
      }
      print(name)
      return
    }

    let inputText = text.isEmpty ? readStdinIfPiped() : text.joined(separator: " ")
    guard let message = inputText, !message.isEmpty else {
      throw ValidationError("No text provided (arg or stdin).")
    }

    // Resolve font URL (default to Standard)
    let desired = fontName?.trimmingCharacters(in: .whitespacesAndNewlines)
    let fontURL: URL? = {
      if let d = desired, !d.isEmpty {
        if d.lowercased() == "random" { return SFKFonts.randomURL() }
        return SFKFonts.find(d)
      }
      return SFKFonts.find("Standard")
    }()
    guard let url = fontURL else {
      throw ValidationError("Unknown or unavailable font: \(desired ?? "(nil)")")
    }
    guard let font = SFKFont.from(url: url) else {
      throw ValidationError("Failed to load font at \(url.path)")
    }

    print(string: message, usingFont: font)
  }
}

private func readStdinIfPiped() -> String? {
  if isatty(fileno(stdin)) == 0 {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    if let s = String(data: data, encoding: .utf8) {
      let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
  }
  return nil
}
