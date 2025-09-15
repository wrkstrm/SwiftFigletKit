import Testing

@testable import SwiftFigletKit

@Suite struct SwiftFigletKitTests {
  @Test func testCreatingACharSetsHeight() {
    let sut = SFKChar(charLines: [
      "  #  $@",
      " ##  $@",
      "# #  $@",
      "  #  $@",
      "  #  $@",
      "  #  $@",
      "#####$@",
    ])
    #expect(sut.height == 7)
  }
}
