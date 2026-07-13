//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

final class PListGeneratorTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("PListGeneratorTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    private struct SampleFlags {
        @FeatureFlagToggle(defaultValue: true, key: "sample_toggle_enabled")
        var sampleToggleEnabled

        @FeatureFlagEnum(defaultValue: .cat, key: "sample_pet")
        var samplePet: TestPetType
    }

    private func readJSON(at url: URL) throws -> Any {
        let data = try Data(contentsOf: url)
        return try JSONSerialization.jsonObject(with: data)
    }

    func testGenerateFeaturesPlistJsonProducesFlatArrayOfEachFlag() throws {
        let outputURL = tempDirectory.appendingPathComponent("Features.json")
        try PListGenerator().generateFeaturesPlistJson(filepath: outputURL, from: SampleFlags(), asPreferenceSpecifier: false)

        let array = try XCTUnwrap(try readJSON(at: outputURL) as? [[String: Any]])
        XCTAssertEqual(array.count, 2)

        let toggleEntry = try XCTUnwrap(array.first(where: { $0["Key"] as? String == "sample_toggle_enabled" }))
        XCTAssertEqual(toggleEntry["Type"] as? String, "PSToggleSwitchSpecifier")
        XCTAssertEqual(toggleEntry["DefaultValue"] as? Bool, true)

        let enumEntry = try XCTUnwrap(array.first(where: { $0["Key"] as? String == "sample_pet" }))
        XCTAssertEqual(enumEntry["Type"] as? String, "PSMultiValueSpecifier")
        XCTAssertEqual(enumEntry["DefaultValue"] as? String, "cat")
    }

    func testGenerateFeaturesPlistJsonWrapsAsPreferenceSpecifierForChildPanes() throws {
        let outputURL = tempDirectory.appendingPathComponent("ChildPane.json")
        try PListGenerator().generateFeaturesPlistJson(filepath: outputURL, from: SampleFlags(), asPreferenceSpecifier: true)

        let dict = try XCTUnwrap(try readJSON(at: outputURL) as? [String: Any])
        let array = try XCTUnwrap(dict["PreferenceSpecifiers"] as? [[String: Any]])
        XCTAssertEqual(array.count, 2)
    }

    func testGenerateFeaturesPlistJsonThrowsForObjectWithNoFlags() {
        struct NoFlags {}
        let outputURL = tempDirectory.appendingPathComponent("Empty.json")

        XCTAssertThrowsError(
            try PListGenerator().generateFeaturesPlistJson(filepath: outputURL, from: NoFlags(), asPreferenceSpecifier: false)
        ) { error in
            guard case PListGenerator.Error.emptyElementsList = error else {
                XCTFail("expected .emptyElementsList, got \(error)")
                return
            }
        }
    }
}
