import Foundation

/// ANSI color utilities for SwiftFigletKit banners.
public enum SFKANSI {
  public enum Color: String, Sendable {
    case none, black, red, green, yellow, blue, magenta, cyan, white
  }

  /// Wrap text in ANSI color codes when appropriate.
  /// - Parameters:
  ///   - text: The text to wrap.
  ///   - color: The desired ANSI color.
  ///   - force: When true, always apply ANSI codes even in Xcode sessions.
  ///   - disableInXcode: When true, suppress ANSI codes if running under Xcode.
  public static func wrap(
    _ text: String,
    color: Color,
    force: Bool = false,
    disableInXcode: Bool = true
  ) -> String {
    if color == .none { return text }
    if disableInXcode && !force
      && ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
    {
      return text
    }
    let code: String = {
      switch color {
      case .none: return ""
      case .black: return "\u{001B}[30m"
      case .red: return "\u{001B}[31m"
      case .green: return "\u{001B}[32m"
      case .yellow: return "\u{001B}[33m"
      case .blue: return "\u{001B}[34m"
      case .magenta: return "\u{001B}[35m"
      case .cyan: return "\u{001B}[36m"
      case .white: return "\u{001B}[37m"
      }
    }()
    return code + text + "\u{001B}[0m"
  }
}
