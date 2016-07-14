import XCTest
@testable import SXF97

class SXF97Tests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SXF97().text, "Hello, World!")
    }


    static var allTests : [(String, (SXF97Tests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
