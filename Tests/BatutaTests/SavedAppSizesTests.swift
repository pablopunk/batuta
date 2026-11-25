import Foundation
import Testing
@testable import Batuta

struct SavedAppSizesTests {
    private let rect = UnitRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)

    @Test func laptopAndExternalListsAreSeparate() {
        var sizes = SavedAppSizes()
        sizes[usesLaptopList: true]["com.apple.Safari"] = rect
        #expect(sizes.laptop["com.apple.Safari"] == rect)
        #expect(sizes.external.isEmpty)
        #expect(!sizes.isEmpty)
    }

    @Test func encodingThenDecodingGivesTheSameSizes() throws {
        var sizes = SavedAppSizes()
        sizes.external["com.apple.Notes"] = rect
        let decoded = try JSONDecoder().decode(SavedAppSizes.self, from: JSONEncoder().encode(sizes))
        #expect(decoded == sizes)
    }
}
