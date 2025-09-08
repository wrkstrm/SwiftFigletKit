import ArgumentParser
import Foundation
import SwiftFigletKit
import SystemScheduler

@main
struct SwiftFigletCLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swift-figlet-cli",
    abstract: "Render text using bundled FIGlet fonts",
    subcommands: [Greet.self, InstallFigletGreet.self]
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
      "Calm is a superpower",
      "Step into the arena",
      "Today is a good day",
      "Finish strong",
      "Consistency compounds",
      "Enjoy the journey",
    ]
    return phrases.randomElement()
  }
}

// Subcommand: install-figlet-greet (LaunchAgent installer using library)
struct InstallFigletGreet: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "install-figlet-greet",
    abstract: "Install a daily LaunchAgent for any program (generic)"
  )

  @Option(name: .customLong("label"), help: "LaunchAgent label")
  var label: String = "com.wrkstrm.figlet-greet"

  @Option(name: .customLong("program"), help: "Program path to run (absolute)")
  var program: String

  @Option(name: .customLong("args"), help: "Program argument (repeatable)")
  var args: [String] = []

  @Option(name: .customLong("hour"), help: "Hour 0-23")
  var hour: Int = 9

  @Option(name: .customLong("min"), help: "Minute 0-59")
  var minute: Int = 0

  @Option(name: .customLong("stdout"), help: "Stdout log path")
  var stdout: String = "~/Library/Logs/figlet-greet.log"

  @Option(name: .customLong("stderr"), help: "Stderr log path")
  var stderr: String = "~/Library/Logs/figlet-greet.err"

  mutating func run() async throws {
    let scheduler = SystemScheduler()
    let dest = try await scheduler.installDaily(
      label: label,
      program: program,
      args: args,
      hour: hour,
      minute: minute,
      stdout: stdout,
      stderr: stderr
    )
    print("Installed and loaded: \(dest)")
    print("Logs: \(stdout) (and \(stderr))")
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
