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
    // Support both plain .flf and compressed .flf.gz; prefer .flf.gz when both exist for same name.
    var best: [String: URL] = [:]  // baseName -> URL
    for url in items {
      let ext = url.pathExtension.lowercased()
      if ext == "flf" {
        let name = url.deletingPathExtension().lastPathComponent
        if best[name] == nil { best[name] = url }
      } else if ext == "gz", url.deletingPathExtension().pathExtension.lowercased() == "flf" {
        // double extension .flf.gz
        let base = url.deletingPathExtension().deletingPathExtension().lastPathComponent
        best[base] = url  // prefer gz
      }
    }
    return best.values.sorted {
      $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent)
        == .orderedAscending
    }
  }

  /// Lists all bundled font display names (without extension), sorted A–Z.
  public static func listNames() -> [String] {
    all()
      .map {
        let last = $0.lastPathComponent
        guard last.lowercased().hasSuffix(".flf.gz") else {
          return $0.deletingPathExtension().lastPathComponent
        }
        return $0.deletingPathExtension().deletingPathExtension().lastPathComponent
      }
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
      let last = url.lastPathComponent
      let base: String
      if last.lowercased().hasSuffix(".flf.gz") {
        base = url.deletingPathExtension().deletingPathExtension().lastPathComponent
      } else {
        base = url.deletingPathExtension().lastPathComponent
      }
      if normalize(base) == wanted || normalize(last) == wanted { return url }
    }
    return nil
  }

  private static func normalize(_ s: String) -> String {
    s.replacingOccurrences(of: "_", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
  }
}
