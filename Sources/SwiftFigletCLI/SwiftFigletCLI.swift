import ArgumentParser
import Foundation
import SwiftFigletKit

@main
struct SwiftFigletCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swift-figlet-cli",
    abstract: "Render text using bundled FIGlet fonts",
    subcommands: [Greet.self]
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

    let message = text.joined(separator: " ")
    guard !message.isEmpty else {
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

// Subcommand: greet (random phrase with random font)
struct Greet: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "greet",
    abstract: "Print an encouraging phrase with a random FIGlet font"
  )

  @Argument(help: "Phrase to render (optional). If omitted, picks a random one.")
  var phrase: [String] = []

  mutating func run() throws {
    let msg = phrase.isEmpty ? (randomPhrase() ?? "You’ve got this") : phrase.joined(separator: " ")
    guard let ascii = SFKRenderer.render(text: msg, fontName: "random") else {
      throw ValidationError("Failed to render with random font")
    }
    print(ascii)
  }

  func randomPhrase() -> String? {
    let phrases = [
      "You’ve got this",
      "Keep going",
      "One step at a time",
      "Make it happen",
      "Stay focused",
      "Be bold today",
      "Progress over perfection",
      "Ship small, ship often",
      "Trust the process",
      "Create with purpose",
      "Curiosity wins",
      "Embrace the challenge",
      "Iterate and learn",
      "Your work matters",
      "Solve one problem",
      "Think clearly",
      "Own the outcome",
      "Small wins compound",
      "Do the hard thing",
      "Start where you are",
      "Practice daily",
      "Craft over chaos",
      "Kindness is strength",
      "Better every day",
      "Stay the course",
      "Earn momentum",
      "Keep it simple",
      "Clarity over cleverness",
      "Design for delight",
      "Move with intent",
      "Learn, unlearn, relearn",
      "Outcome over output",
      "Focus beats luck",
      "Build for users",
    ]
    return phrases.randomElement()
  }
}
