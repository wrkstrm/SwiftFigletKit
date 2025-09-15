import Foundation
import Testing

@testable import SwiftFigletKit

@Suite struct SFKFigletFileTests {
  @Test func test_Given_Empty_HeaderLine_CreateHeader_Should_Return_Nil() {
    let headerLine = ""
    let sut = SFKFigletFile.Header.createFigletFontHeader(from: headerLine)
    #expect(sut == nil)
  }

  @Test func test_Given_Malformed_HeaderLine_CreateHeader_Should_Return_Nil() {
    let headerLine = "flf$ 2 1 8 -1 13"
    let sut = SFKFigletFile.Header.createFigletFontHeader(from: headerLine)
    #expect(sut == nil)
  }

  @Test func test_Given_NonEmpty_HeaderLine_CreateHeader_Should_Return_Header() {
    let headerLine = "flf2a$ 2 1 8 -1 13"
    let sut = SFKFigletFile.Header.createFigletFontHeader(from: headerLine)
    #expect(sut != nil)
    #expect(sut?.hardBlank == "$")
    #expect(sut?.height == 2)
    #expect(sut?.baseline == 1)
    #expect(sut?.maxLength == 8)
    #expect(sut?.oldLayout == -1)
    #expect(sut?.commentLines == 13)
    #expect(sut?.commentDirection == SFKFigletFile.PrintDirection.leftToRight)
  }

  @Test func test_Given_NonEmpty_ShortHeaderLine_CreateHeader_Should_Return_Header() {
    let headerLine = "flf2a$ 2 1"
    let sut = SFKFigletFile.Header.createFigletFontHeader(from: headerLine)
    #expect(sut != nil)
    #expect(sut?.hardBlank == "$")
    #expect(sut?.height == 2)
    #expect(sut?.baseline == 1)
    #expect(sut?.maxLength == 0)
    #expect(sut?.oldLayout == 0)
    #expect(sut?.commentLines == 0)
    #expect(sut?.commentDirection == SFKFigletFile.PrintDirection.leftToRight)
  }

  @Test func test_Given_NonExistingFile_Should_ReturnNil() {
    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let resourceURL = thisDirectory.appendingPathComponent("testFonts/This file is not there")

    let figletFile = SFKFigletFile.from(url: resourceURL)

    #expect(figletFile == nil)
  }

  @Test func test_Given_File_Should_Load_FigletFont() {
    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let resourceURL = thisDirectory.appendingPathComponent("testFonts/Broadway.flf")

    let figletFile = SFKFigletFile.from(url: resourceURL)

    #expect(figletFile != nil)
    #expect(figletFile?.header.commentLines == 29)

    #expect(figletFile?.headerLines.count == 30)  // 29 comment lines + 1 line header

    #expect(figletFile?.headerLines.first == "flf2a$ 11 11 36 2 29")
    #expect(figletFile?.headerLines.last == "")
    #expect(figletFile?.lines.first == "$        $@")
  }

  @Test func test_Given_BrokenFile_Should_Load_With_Latin1_Fallback() {
    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let resourceURL = thisDirectory.appendingPathComponent("testFonts/Wow.flf")

    let figletFile = SFKFigletFile.from(url: resourceURL)
    #expect(figletFile != nil)
  }
}
