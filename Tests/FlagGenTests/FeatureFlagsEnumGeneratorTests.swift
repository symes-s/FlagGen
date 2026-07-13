//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

final class FeatureFlagsEnumGeneratorTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("FeatureFlagsEnumGeneratorTests-\(UUID().uuidString)", isDirectory: true)
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

    private func generatedEnumSource(from generator: FeatureFlagsEnumGenerator) throws -> String {
        try generator.generateEnum(to: "FeatureFlags")
        let fileURL = tempDirectory
            .appendingPathComponent("FeatureFlags", isDirectory: true)
            .appendingPathComponent("Generated/Enums", isDirectory: true)
            .appendingPathComponent("FeatureFlagsEnum.swift")
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    func testGenerateEnumWritesACaseForEachFlagKeyedByItsLocalKey() throws {
        let generator = FeatureFlagsEnumGenerator(directoryURL: tempDirectory)
        generator.buildEnum(from: SampleFlags())

        let source = try generatedEnumSource(from: generator)

        XCTAssertTrue(source.contains(#"case sampleToggle = "sample_toggle_enabled""#))
        XCTAssertTrue(source.contains(#"case samplePet = "sample_pet""#))
    }

    func testGenerateEnumDeclaresAPublicCaseIterableStringEnum() throws {
        let generator = FeatureFlagsEnumGenerator(directoryURL: tempDirectory)
        generator.buildEnum(from: SampleFlags())

        let source = try generatedEnumSource(from: generator)

        XCTAssertTrue(source.contains("public enum FeatureFlagsEnum: String, CaseIterable {"))
    }

    func testGenerateEnumValueTypeExtensionDistinguishesNonBoolFlags() throws {
        let generator = FeatureFlagsEnumGenerator(directoryURL: tempDirectory)
        generator.buildEnum(from: SampleFlags())

        let source = try generatedEnumSource(from: generator)

        // Bool-backed toggles fall through to the `default` case; only the non-Bool
        // enum flag needs an explicit case in the `valueType` extension.
        XCTAssertTrue(source.contains("case .samplePet: TestPetType.self"))
        XCTAssertFalse(source.contains("case .sampleToggle:"))
        XCTAssertTrue(source.contains("Bool.self"))
    }

    func testBuildEnumAccumulatesMetadataAcrossMultipleCalls() throws {
        struct OtherFlags {
            @FeatureFlagToggle(defaultValue: false, key: "other_toggle_enabled")
            var otherToggleEnabled
        }

        let generator = FeatureFlagsEnumGenerator(directoryURL: tempDirectory)
        generator.buildEnum(from: SampleFlags())
        generator.buildEnum(from: OtherFlags())

        let source = try generatedEnumSource(from: generator)

        XCTAssertTrue(source.contains(#"case sampleToggle = "sample_toggle_enabled""#))
        XCTAssertTrue(source.contains(#"case samplePet = "sample_pet""#))
        XCTAssertTrue(source.contains(#"case otherToggle = "other_toggle_enabled""#))
    }

    func testGenerateUserDefaultsExtensionsWritesAFile() throws {
        let generator = FeatureFlagsEnumGenerator(directoryURL: tempDirectory)
        generator.buildEnum(from: SampleFlags())
        try generator.generateUserDefaultsExtensions(to: "FeatureFlags")

        let fileURL = tempDirectory
            .appendingPathComponent("FeatureFlags", isDirectory: true)
            .appendingPathComponent("Generated/Extensions", isDirectory: true)
            .appendingPathComponent("UserDefaults+Publishers.swift")
        let source = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(source.contains("extension UserDefaults"))
        XCTAssertTrue(source.contains("sampleToggle"))
    }
}
