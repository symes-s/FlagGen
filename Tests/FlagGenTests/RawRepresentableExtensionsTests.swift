//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

/// Covers the identity `RawRepresentable` conformances (`Bool`/`Int`/`Double`/`String`)
/// that let plain flag types flow through the same `RawRepresentable`-generic APIs as
/// custom enums.
final class RawRepresentableExtensionsTests: XCTestCase {
    func testBoolRawValueRoundTrip() {
        XCTAssertEqual(true.rawValue, true)
        XCTAssertEqual(Bool(rawValue: false), false)
    }

    func testIntRawValueRoundTrip() {
        XCTAssertEqual(5.rawValue, 5)
        XCTAssertEqual(Int(rawValue: 5), 5)
    }

    func testDoubleRawValueRoundTrip() {
        XCTAssertEqual(1.5.rawValue, 1.5)
        XCTAssertEqual(Double(rawValue: 1.5), 1.5)
    }

    func testStringRawValueRoundTrip() {
        XCTAssertEqual("hello".rawValue, "hello")
        XCTAssertEqual(String(rawValue: "hello"), "hello")
    }
}
