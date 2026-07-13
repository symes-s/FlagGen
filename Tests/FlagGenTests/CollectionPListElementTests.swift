//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

final class CollectionPListElementTests: XCTestCase {
    func testEncodedProducesJSONArray() throws {
        let elements: [PListElement] = [
            PListToggle(key: "a_enabled", defaultValue: true),
            PListGroup(title: "Group", footerText: nil)
        ]
        let data = try elements.encoded(by: JSONEncoder())
        let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertEqual(array?.count, 2)
    }

    func testEmptyCollectionEncodesToEmptyArray() throws {
        let elements: [PListElement] = []
        let data = try elements.encoded(by: JSONEncoder())
        XCTAssertEqual(String(data: data, encoding: .utf8), "[]")
    }

    func testJsonHelperReturnsStringRepresentation() {
        let elements: [PListElement] = [PListGroup(title: "Group", footerText: nil)]
        let json = elements.json(by: JSONEncoder())
        XCTAssertNotNil(json)
        XCTAssertTrue(json?.contains("PSGroupSpecifier") ?? false)
    }

    func testPrettyPrintedEncodingUsesNewlineSeparators() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let elements: [PListElement] = [
            PListGroup(title: "A", footerText: nil),
            PListGroup(title: "B", footerText: nil)
        ]
        let data = try elements.encoded(by: encoder)
        let string = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(string.hasPrefix("[\n"))
        XCTAssertTrue(string.hasSuffix("\n]"))
        XCTAssertTrue(string.contains(",\n"))
    }
}
