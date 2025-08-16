//
//  SFKFontTests.swift
//  SwiftFigletKitTests
//
//  Created by Diego Freniche Brito on 10/05/2020.
//

import Foundation
import Testing

@testable import SwiftFigletKit

@Suite struct SFKFontTests {
  @Test func test_Given_FontFile_LoadsFont() {
    let sampleA = [
      "                      ",
      "         .8.          ",
      "        .888.         ",
      "       :88888.        ",
      "      . `88888.       ",
      "     .8. `88888.      ",
      "    .8`8. `88888.     ",
      "   .8' `8. `88888.    ",
      "  .8'   `8. `88888.   ",
      " .888888888. `88888.  ",
      ".8'       `8. `88888. ",
    ]

    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let resourceURL = thisDirectory.appendingPathComponent("testFonts/Broadway.flf")

    let font = SFKFont.from(url: resourceURL)
    #expect(font != nil)
    #expect(font?.height == 11)
    #expect(font?.fkChar["A"]?.lines == sampleA)
  }

  @Test func test_Given_FontFile_Font_ContainsFigletFontFile() {
    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let resourceURL = thisDirectory.appendingPathComponent("testFonts/Broadway.flf")

    let font = SFKFont.from(url: resourceURL)
    #expect(font?.figletFile != nil)
    #expect(font?.figletFile?.header.commentLines == 29)
    #expect(font?.figletFile?.header.hardBlank == "$")
  }
}
