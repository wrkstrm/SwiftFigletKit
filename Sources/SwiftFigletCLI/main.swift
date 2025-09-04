import Foundation
import SwiftFigletKit

struct CLI {
  struct Options {
    var listFonts = false
    var fontName: String? = nil
    var text: String? = nil
  }

  static func parse(_ args: [String]) -> Options {
    var opts = Options()
    var i = 0
    while i < args.count {
      let a = args[i]
      switch a {
      case "-h", "--help":
        printUsage()
        exit(0)
      case "-l", "--list-fonts":
        opts.listFonts = true
        i += 1
      case "-f", "--font":
        if i + 1 < args.count { opts.fontName = args[i + 1]; i += 2 } else { i += 1 }
      default:
        // Remaining args compose the text
        let remaining = Array(args[i...])
        opts.text = remaining.joined(separator: " ")
        i = args.count
      }
    }
    return opts
  }

  static func printUsage() {
    let exe = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "swiftfiglet"
    let msg = """
    Usage: \(exe) [options] <text>

    Options:
      -f, --font <name>     Use a specific font (base name or .flf)
      -l, --list-fonts      List bundled fonts and exit
      -h, --help            Show this help message

    Examples:
      \(exe) "Hello World"
      \(exe) -f Standard "Banner"
      echo hello | \(exe) -f Slant
    """
    print(msg)
  }
}

func readStdinIfPiped() -> String? {
  // If stdin is not a TTY, read it
  if isatty(fileno(stdin)) == 0 {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    if let s = String(data: data, encoding: .utf8) {
      let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
  }
  return nil
}

func run() -> Int32 {
  let args = Array(CommandLine.arguments.dropFirst())
  let opts = CLI.parse(args)

  if opts.listFonts {
    let names = SFKFonts.listNames()
    if names.isEmpty {
      fputs("No bundled fonts found.\n", stderr)
      return 1
    }
    for n in names { print(n) }
    return 0
  }

  let inputText = opts.text ?? readStdinIfPiped()
  guard let text = inputText, !text.isEmpty else {
    CLI.printUsage()
    return 1
  }

  // Resolve font URL
  let fontURL: URL?
  if let name = opts.fontName, !name.isEmpty {
    fontURL = SFKFonts.find(name)
    if fontURL == nil {
      fputs("Unknown font: \(name)\n", stderr)
      return 2
    }
  } else {
    // Default to Standard
    fontURL = SFKFonts.find("Standard")
  }

  guard let url = fontURL, let font = SFKFont.from(url: url) else {
    fputs("Failed to load font.\n", stderr)
    return 3
  }

  print(string: text, usingFont: font)
  return 0
}

exit(run())

