import Foundation

// Access ANSI utilities in this module
// (same target, so no explicit import beyond module scope is needed)

public enum SFKRenderer {
  public enum ANSIColor: String, Sendable {
    case none, black, red, green, yellow, blue, magenta, cyan, white
  }

  private static let defaultPalette: [ANSIColor] = [.red, .yellow, .green, .cyan, .blue, .magenta]

  // Build lines for a given font
  private static func buildLines(text: String, using font: SFKFont) -> [String] {
    guard font.height > 0 else { return [] }
    var lines: [String] = Array(repeating: "", count: font.height)
    for i in 0..<font.height {
      var row = ""
      for c in text {
        if let ch = font.fkChar[c], i < ch.lines.count {
          row += ch.lines[i]
        }
      }
      lines[i] = row
    }
    return lines
  }

  private static func wrap(_ text: String, color: ANSIColor, force: Bool, disableInXcode: Bool)
    -> String
  {
    if color == .none { return text }
    if disableInXcode, !force,
      ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    {
      return text
    }
    let code =
      switch color {
      case .none: ""
      case .black: "\u{001B}[30m"
      case .red: "\u{001B}[31m"
      case .green: "\u{001B}[32m"
      case .yellow: "\u{001B}[33m"
      case .blue: "\u{001B}[34m"
      case .magenta: "\u{001B}[35m"
      case .cyan: "\u{001B}[36m"
      case .white: "\u{001B}[37m"
      }
    return code + text + "\u{001B}[0m"
  }

  /// Render text using a previously loaded font.
  public static func render(
    text: String,
    using font: SFKFont,
    color: ANSIColor = .none,
    forceColor: Bool = false,
    disableColorInXcode: Bool = true,
  ) -> String {
    let lines = buildLines(text: text, using: font)
    let rendered = lines.joined(separator: "\n") + "\n"
    return wrap(rendered, color: color, force: forceColor, disableInXcode: disableColorInXcode)
  }

  /// Render text using a font at URL. Returns nil if loading fails.
  public static func render(
    text: String,
    fontURL: URL,
    color: ANSIColor = .none,
    forceColor: Bool = false,
    disableColorInXcode: Bool = true,
  ) -> String? {
    guard let font = SFKFont.from(url: fontURL) else { return nil }
    return render(
      text: text, using: font, color: color, forceColor: forceColor,
      disableColorInXcode: disableColorInXcode,
    )
  }

  /// Render text using a named font (base name or .flf). Special name "random" uses a random font.
  /// Defaults to "Standard" when `name` is nil.
  public static func render(
    text: String,
    fontName name: String?,
    color: ANSIColor = .none,
    forceColor: Bool = false,
    disableColorInXcode: Bool = true,
  ) -> String? {
    let chosenURL: URL? =
      if let name, !name.isEmpty {
        if name.lowercased() == "random" {
          SFKFonts.randomURL()
        } else {
          SFKFonts.find(name)
        }
      } else {
        SFKFonts.find("Standard")
      }
    guard let url = chosenURL else { return nil }
    return render(
      text: text,
      fontURL: url,
      color: color,
      forceColor: forceColor,
      disableColorInXcode: disableColorInXcode,
    )
  }

  /// Render using a gradient across lines.
  public static func renderGradientLines(
    text: String,
    using font: SFKFont,
    palette: [ANSIColor]? = nil,
    randomizePalette: Bool = false,
    forceColor: Bool = false,
    disableColorInXcode: Bool = true,
  ) -> String {
    let lines = buildLines(text: text, using: font)
    var colors = palette ?? defaultPalette
    if randomizePalette { colors.shuffle() }
    guard !colors.isEmpty else { return lines.joined(separator: "\n") + "\n" }
    let colored = lines.enumerated().map { idx, line in
      wrap(
        line, color: colors[idx % colors.count], force: forceColor,
        disableInXcode: disableColorInXcode,
      )
    }
    return colored.joined(separator: "\n") + "\n"
  }

  public static func renderGradientLines(
    text: String,
    fontURL: URL,
    palette: [ANSIColor]? = nil,
    randomizePalette: Bool = false,
    forceColor: Bool = false,
    disableColorInXcode: Bool = true,
  ) -> String? {
    guard let font = SFKFont.from(url: fontURL) else { return nil }
    return renderGradientLines(
      text: text, using: font, palette: palette, randomizePalette: randomizePalette,
      forceColor: forceColor, disableColorInXcode: disableColorInXcode,
    )
  }

  public static func renderGradientLines(
    text: String,
    fontName name: String?,
    palette: [ANSIColor]? = nil,
    randomizePalette: Bool = false,
    forceColor: Bool = false,
    disableColorInXcode: Bool = true,
  ) -> String? {
    let chosenURL: URL? =
      if let name, !name.isEmpty {
        (name.lowercased() == "random") ? SFKFonts.randomURL() : SFKFonts.find(name)
      } else {
        SFKFonts.find("Standard")
      }
    guard let url = chosenURL else { return nil }
    return renderGradientLines(
      text: text, fontURL: url, palette: palette, randomizePalette: randomizePalette,
      forceColor: forceColor, disableColorInXcode: disableColorInXcode,
    )
  }
}
