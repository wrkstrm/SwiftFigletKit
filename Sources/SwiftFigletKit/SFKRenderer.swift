import Foundation

public enum SFKRenderer {
  /// Render text using a previously loaded font.
  public static func render(text: String, using font: SFKFont) -> String {
    guard font.height > 0 else { return "" }
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
    return lines.joined(separator: "\n") + "\n"
  }

  /// Render text using a font at URL. Returns nil if loading fails.
  public static func render(text: String, fontURL: URL) -> String? {
    guard let font = SFKFont.from(url: fontURL) else { return nil }
    return render(text: text, using: font)
  }

  /// Render text using a named font (base name or .flf). Special name "random" uses a random font.
  /// Defaults to "Standard" when `name` is nil.
  public static func render(text: String, fontName name: String?) -> String? {
    let chosenURL: URL?
    if let name = name, !name.isEmpty {
      if name.lowercased() == "random" {
        chosenURL = SFKFonts.randomURL()
      } else {
        chosenURL = SFKFonts.find(name)
      }
    } else {
      chosenURL = SFKFonts.find("Standard")
    }
    guard let url = chosenURL else { return nil }
    return render(text: text, fontURL: url)
  }
}
