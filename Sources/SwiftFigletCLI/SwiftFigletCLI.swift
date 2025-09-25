import ArgumentParser
import Foundation
import SwiftFigletKit
import CommonShell
import CommonProcess

@main
struct SwiftFigletCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "swift-figlet-cli",
    abstract: "Render text using bundled FIGlet fonts",
    subcommands: [Greet.self, Doctor.self],
  )

  @Flag(name: .customLong("list-fonts"), help: "List bundled fonts and exit")
  var listFonts: Bool = false

  @Flag(name: .customLong("random-font"), help: "Print a random bundled font name and exit")
  var randomFontOnly: Bool = false

  @Option(name: .customLong("font"), help: "Font to use (base name, 'random', or .flf)")
  var fontName: String?

  @Argument(help: "Text to render. If omitted, reads from stdin when piped.")
  var text: [String] = []

  func run() async throws {
    // Special-case: allow `swift-figlet-cli doctor` to work even if subcommand
    // parsing is shadowed by positional arguments.
    if text.count == 1, text.first?.lowercased() == "doctor" {
      try await Self.performDoctor(verbose: false)
      return
    }
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

  private static func performDoctor(verbose: Bool) async throws {
    var ok = true
    let gun1 = await checkTool(["gunzip", "--version"]) 
    let gun2 = await checkTool(["gzip", "--version"]) 
    let gunzipOK = gun1 || gun2
    if gunzipOK {
      print("[OK] gzip found (gunzip/gzip available)")
    } else {
      ok = false
      print("[FAIL] gzip not found on PATH")
    }
    let urls = SFKFonts.all()
    if let gzURL = urls.first(where: { $0.lastPathComponent.lowercased().hasSuffix(".flf.gz") }) {
      if verbose { print("[INFO] Testing inflate: \(gzURL.lastPathComponent)") }
      if let file = SFKFigletFile.from(url: gzURL), file.header.height > 0 {
        print("[OK] Inflated and parsed a bundled .flf.gz font")
      } else {
        ok = false
        print("[FAIL] Could not inflate and parse a bundled .flf.gz font")
      }
    } else {
      ok = false
      print("[FAIL] No .flf.gz resources found (ResourcesGZ/Fonts)")
    }
    if !ok { throw ValidationError("Doctor found issues") }
  }

  private static func checkTool(_ args: [String]) async -> Bool {
    let shell = CommonShell()
    do {
      let out = try await shell.withExec(reference: .name(args.first ?? "")).launch(options: Array(args.dropFirst()))
      switch out.exitStatus { case .exited(let code): return code == 0; case .signalled: return false }
    } catch { return false }
  }
}

// Subcommand: greet (random phrase with random font)
struct Greet: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "greet",
    abstract: "Print an encouraging phrase with a random FIGlet font",
  )

  @Argument(help: "Phrase to render (optional). If omitted, picks a random one.")
  var phrase: [String] = []

  mutating func run() async throws {
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

// Subcommand: doctor (environment and resource checks)
struct Doctor: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "doctor",
    abstract: "Verify gzip availability and font inflation on this system",
  )

  @Flag(name: .shortAndLong, help: "Print additional diagnostics")
  var verbose: Bool = false

  mutating func run() async throws {
    var ok = true

    // 1) Check gunzip/gzip availability
    let gun1 = await Self.checkTool(["gunzip", "--version"]) 
    let gun2 = await Self.checkTool(["gzip", "--version"]) 
    let gunzipOK = gun1 || gun2
    if gunzipOK {
      print("[OK] gzip found (gunzip/gzip available)")
    } else {
      ok = false
      print("[FAIL] gzip not found on PATH (gunzip/gzip unavailable)")
    }

    // 2) Find a gz font in bundled resources
    let urls = SFKFonts.all()
    let gz = urls.first { $0.lastPathComponent.lowercased().hasSuffix(".flf.gz") }
    if let gzURL = gz {
      if verbose { print("[INFO] Testing inflate: \(gzURL.lastPathComponent)") }
      if let file = SFKFigletFile.from(url: gzURL) {
        if file.header.height > 0 {
          print("[OK] Inflated and parsed font header (height=\(file.header.height))")
        } else {
          ok = false
          print("[FAIL] Inflated but header invalid (height=\(file.header.height))")
        }
      } else {
        ok = false
        print("[FAIL] Could not inflate and parse a bundled .flf.gz font")
      }
    } else {
      ok = false
      print("[FAIL] No .flf.gz resources found; ensure ResourcesGZ/Fonts is bundled")
    }

    guard ok else {
      throw ValidationError("Doctor found issues (see above)")
    }
    if verbose { print("[OK] Environment ready for SwiftFigletKit on this platform") }
  }

  private static func checkTool(_ args: [String]) async -> Bool {
    let shell = CommonShell()
    do {
      let out = try await shell.withExec(reference: .name(args.first ?? "")).launch(options: Array(args.dropFirst()))
      switch out.exitStatus { case .exited(let code): return code == 0; case .signalled: return false }
    } catch { return false }
  }
}
