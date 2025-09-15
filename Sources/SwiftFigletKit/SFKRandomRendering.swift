import Foundation

// MARK: - Public strategies and options

/// Strategy to choose which FIGlet font to use.
public enum SFKFontStrategy: Sendable {
  /// Use a specific font name (case-insensitive; accepts base name or `.flf`).
  case named(String)
  /// Choose a random font, optionally excluding some names.
  case random(excluding: [String] = [])
}

/// Strategy to colorize output when rendering banners.
public enum SFKColorStrategy: Sendable {
  /// Render with a single ANSI color.
  case single(SFKRenderer.ANSIColor)
  /// Pick a single color randomly from a palette (defaults to `SFKPalettes.singleDefault`).
  case singleRandom(palette: [SFKRenderer.ANSIColor]? = nil)
  /// Render with a fixed palette across lines, cycling colors per line.
  case gradient(palette: [SFKRenderer.ANSIColor])
  /// Pick a gradient palette (or use default) and optionally shuffle it.
  case gradientRandom(palette: [SFKRenderer.ANSIColor]? = nil, shuffle: Bool = true)
  /// Choose between single and gradient at runtime with a probability.
  case mixedRandom(
    gradientProbability: Double = 0.5,
    singlePalette: [SFKRenderer.ANSIColor]? = nil,
    gradientPalette: [SFKRenderer.ANSIColor]? = nil
  )
}

/// Rendering options for high-level banner helpers.
public struct SFKRenderOptions: Sendable {
  /// Optional string placed before the rendered text.
  public var prefix: String? = nil
  /// Optional string placed after the rendered text.
  public var suffix: String? = nil
  /// When true, appends a trailing newline when falling back to plain text.
  public var newline: Bool = false
  /// Reserved for future use (no wrapping currently performed).
  public var wrapWidth: Int? = nil // reserved for future use
  /// Optional seed for deterministic font/color selection across runs.
  public var seed: UInt64? = nil
  /// Force ANSI color even in Xcode consoles.
  public var forceColor: Bool = false
  /// Disable ANSI color in Xcode consoles (default true).
  public var disableColorInXcode: Bool = true

  public init(
    prefix: String? = nil,
    suffix: String? = nil,
    newline: Bool = false,
    wrapWidth: Int? = nil,
    seed: UInt64? = nil,
    forceColor: Bool = false,
    disableColorInXcode: Bool = true
  ) {
    self.prefix = prefix
    self.suffix = suffix
    self.newline = newline
    self.wrapWidth = wrapWidth
    self.seed = seed
    self.forceColor = forceColor
    self.disableColorInXcode = disableColorInXcode
  }
}

/// Default color palettes for single and gradient modes.
public enum SFKPalettes {
  /// Default palette for single-color rendering.
  public static let singleDefault: [SFKRenderer.ANSIColor] =
    [.red, .yellow, .green, .cyan, .blue, .magenta, .white]
  /// Default palette for gradient rendering (cycled by line).
  public static let gradientDefault: [SFKRenderer.ANSIColor] =
    [.red, .yellow, .green, .cyan, .blue, .magenta]
}

// MARK: - Seeded RNG

struct SFKSeededLCG: RandomNumberGenerator {
  private var state: UInt64
  init(seed: UInt64) { self.state = seed &* 6364136223846793005 &+ 1 }
  mutating func next() -> UInt64 {
    state = 2862933555777941757 &* state &+ 3037000493
    return state
  }
}

// MARK: - Rendering convenience

extension SFKRenderer {
  private static func toANSI(_ c: SFKRenderer.ANSIColor) -> SFKANSI.Color {
    switch c {
    case .none: return .none
    case .black: return .black
    case .red: return .red
    case .green: return .green
    case .yellow: return .yellow
    case .blue: return .blue
    case .magenta: return .magenta
    case .cyan: return .cyan
    case .white: return .white
    }
  }
  /// High-level rendering combining font and color strategies with optional seeding.
  ///
  /// - Parameters:
  ///   - text: The text to render.
  ///   - font: Font selection strategy (named or random with exclusions).
  ///   - color: Colorization strategy (single/gradient/random/mixed).
  ///   - options: Rendering options (seed, prefix/suffix, color flags).
  /// - Returns: A colored banner string. Falls back to a plain ANSI-colored line when fonts are unavailable.
  public static func render(
    text: String,
    font: SFKFontStrategy,
    color: SFKColorStrategy,
    options: SFKRenderOptions = .init()
  ) -> String {
    // Resolve RNG
    let rng = options.seed.map { SFKSeededLCG(seed: $0) }

    // Resolve font URL or object
    let chosenFontURL: URL? = {
      switch font {
      case .named(let name):
        return SFKFonts.find(name)
      case .random(let excluding):
        let all = SFKFonts.listNames().filter { !excluding.contains($0) }
        guard !all.isEmpty else { return SFKFonts.randomURL() }
        if var rr = rng {
          let idx = Int(rr.next() % UInt64(all.count))
          return SFKFonts.find(all[idx])
        } else {
          return SFKFonts.find(all.randomElement() ?? "")
        }
      }
    }()

    // Load font if possible
    let figlet: SFKFont? = chosenFontURL.flatMap { SFKFont.from(url: $0) }

    // Prepare text with prefix/suffix
    let combined: String = (options.prefix ?? "") + text + (options.suffix ?? "")

    // Resolve color plan and render
    switch color {
    case .single(let c):
      if let fig = figlet { return SFKRenderer.render(text: combined, using: fig, color: c, forceColor: options.forceColor, disableColorInXcode: options.disableColorInXcode) }
      // Fallback: plain line with ANSI color
      return SFKANSI.wrap(combined + (options.newline ? "\n" : ""), color: toANSI(c))

    case .singleRandom(let palette):
      let paletteToUse = palette ?? SFKPalettes.singleDefault
      let color: SFKRenderer.ANSIColor = {
        if var rr = rng { return paletteToUse[Int(rr.next() % UInt64(paletteToUse.count))] }
        return paletteToUse.randomElement() ?? .white
      }()
      if let fig = figlet { return SFKRenderer.render(text: combined, using: fig, color: color, forceColor: options.forceColor, disableColorInXcode: options.disableColorInXcode) }
      return SFKANSI.wrap(combined + (options.newline ? "\n" : ""), color: toANSI(color))

    case .gradient(let palette):
      if let fig = figlet {
        let s = SFKRenderer.renderGradientLines(text: combined, using: fig, palette: palette, randomizePalette: false, forceColor: options.forceColor, disableColorInXcode: options.disableColorInXcode)
        return options.newline ? s : s
      }
      // Fallback: map gradient to first color
      let c = palette.first ?? .white
      return SFKANSI.wrap(combined + (options.newline ? "\n" : ""), color: toANSI(c))

    case .gradientRandom(let palette, let shuffle):
      var pal = palette ?? SFKPalettes.gradientDefault
      if shuffle {
        if var rr = rng {
          // Fisher–Yates with seeded RNG
          for i in stride(from: pal.count - 1, through: 1, by: -1) {
            let j = Int(rr.next() % UInt64(i + 1))
            pal.swapAt(i, j)
          }
        } else {
          pal.shuffle()
        }
      }
      if let fig = figlet {
        let s = SFKRenderer.renderGradientLines(text: combined, using: fig, palette: pal, randomizePalette: false, forceColor: options.forceColor, disableColorInXcode: options.disableColorInXcode)
        return options.newline ? s : s
      }
      let c = pal.first ?? .white
      return SFKANSI.wrap(combined + (options.newline ? "\n" : ""), color: toANSI(c))

    case .mixedRandom(let p, let singlePal, let gradPal):
      let threshold = max(0.0, min(1.0, p))
      let chooseGradient: Bool = {
        if var rr = rng { return (Double(rr.next() % 1_000_000) / 1_000_000.0) < threshold }
        return Double.random(in: 0...1) < threshold
      }()
      if chooseGradient {
        return render(text: text, font: font, color: .gradientRandom(palette: gradPal, shuffle: true), options: options)
      } else {
        return render(text: text, font: font, color: .singleRandom(palette: singlePal), options: options)
      }
    }
  }

  /// Convenience for typical banner use: random font with a mixed color strategy.
  ///
  /// - Parameters:
  ///   - text: The text to render.
  ///   - color: Color strategy. Defaults to a 50/50 single vs. gradient mix.
  ///   - options: Rendering options; pass `seed` for deterministic output.
  /// - Returns: A colored banner string or a plain ANSI-colored line if fonts are unavailable.
  public static func renderRandomBanner(
    text: String,
    color: SFKColorStrategy = .mixedRandom(),
    options: SFKRenderOptions = .init()
  ) -> String {
    render(text: text, font: .random(), color: color, options: options)
  }
}
