//
//  SFKFonts.swift
//  SwiftFigletKit
//
//  Lightweight helper to access bundled FIGlet fonts.

import Foundation

public enum SFKFonts {
  /// Returns URLs for all bundled `.flf` fonts.
  public static func all() -> [URL] {
    guard let root = Bundle.module.resourceURL?.appendingPathComponent("Fonts", isDirectory: true)
    else { return [] }

    let fm = FileManager.default
    guard let items = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
      return []
    }
    return items.filter { $0.pathExtension.lowercased() == "flf" }
  }

  /// Lists all bundled font display names (without extension), sorted A–Z.
  public static func listNames() -> [String] {
    all()
      .map { $0.deletingPathExtension().lastPathComponent }
      .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  }

  /// Returns a random bundled font name.
  public static func randomName() -> String? {
    listNames().randomElement()
  }

  /// Returns a random bundled font URL.
  public static func randomURL() -> URL? {
    all().randomElement()
  }

  /// Finds a font URL by name. Accepts either a base name or filename with extension.
  /// Comparison is case-insensitive; space and underscore differences are tolerated.
  public static func find(_ name: String) -> URL? {
    let wanted = normalize(name)
    for url in all() {
      let base = url.deletingPathExtension().lastPathComponent
      let withExt = url.lastPathComponent
      if normalize(base) == wanted || normalize(withExt) == wanted {
        return url
      }
    }
    return nil
  }

  private static func normalize(_ s: String) -> String {
    s.replacingOccurrences(of: "_", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
  }
}
