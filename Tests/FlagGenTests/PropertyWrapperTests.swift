//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

/// Covers `wrappedValue`, `pListElements`, and related metadata for each `@FeatureFlag*`
/// property wrapper, using an in-memory `MockFeatureFlagProvider` registered on the
/// shared `FeatureFlagService.default` singleton. Publisher behaviour (which needs a
/// real, observable `UserDefaults`-backed provider) is covered separately in
/// `PropertyWrapperPublisherTests`.
final class PropertyWrapperTests: XCTestCase {
    private var mockProvider: MockFeatureFlagProvider!

    override func setUp() {
        super.setUp()
        mockProvider = MockFeatureFlagProvider()
        FeatureFlagService.default.setProviders([mockProvider])
    }

    override func tearDown() {
        FeatureFlagService.default.setProviders([])
        mockProvider = nil
        super.tearDown()
    }

    // MARK: - FeatureFlagToggle

    func testToggleWrappedValueDefault() {
        let toggle = FeatureFlagToggle(defaultValue: true, key: "toggle_key")
        XCTAssertTrue(toggle.wrappedValue)
    }

    func testToggleWrappedValueReflectsProviderOverride() {
        let toggle = FeatureFlagToggle(defaultValue: true, key: "toggle_key")
        mockProvider.set(value: false, for: "toggle_key")
        XCTAssertFalse(toggle.wrappedValue)
    }

    func testToggleKeysDictInit() {
        let toggle = FeatureFlagToggle(defaultValue: true, keysDict: [.developmentLocal: "toggle_key"])
        XCTAssertEqual(toggle.keys.first?.key, "toggle_key")
        XCTAssertEqual(toggle.keys.first?.provider, .developmentLocal)
    }

    func testToggleProvidersInitDedupesProviders() {
        let toggle = FeatureFlagToggle(defaultValue: true, key: "toggle_key", providers: [.developmentLocal, .developmentLocal])
        XCTAssertEqual(toggle.keys.count, 1)
    }

    func testTogglePListElementsWithoutTitle() {
        let toggle = FeatureFlagToggle(defaultValue: true, key: "toggle_key")
        XCTAssertEqual(toggle.pListElements.count, 1)
    }

    func testToggleDefaultType() {
        let toggle = FeatureFlagToggle(defaultValue: true, key: "toggle_key")
        XCTAssertEqual(toggle.defaultType, "Bool")
    }

    // MARK: - FeatureFlagEnum

    func testEnumWrappedValueDefault() {
        let flag = FeatureFlagEnum(defaultValue: TestPetType.cat, key: "pet_key")
        XCTAssertEqual(flag.wrappedValue, .cat)
    }

    func testEnumWrappedValueReflectsProviderOverride() {
        let flag = FeatureFlagEnum(defaultValue: TestPetType.cat, key: "pet_key")
        mockProvider.set(value: TestPetType.dog, for: "pet_key")
        XCTAssertEqual(flag.wrappedValue, .dog)
    }

    func testEnumDefaultValueMatchesPListEntryDefault() {
        let flag = FeatureFlagEnum(defaultValue: TestPetType.dog, key: "pet_key")
        XCTAssertEqual(flag.defaultValue, .dog)
    }

    func testEnumPListElements() {
        let flag = FeatureFlagEnum(defaultValue: TestPetType.cat, key: "pet_key")
        XCTAssertEqual(flag.pListElements.count, 1)
    }

    // MARK: - FeatureFlagRadioGroup

    func testRadioGroupWrappedValueDefault() {
        let radio = FeatureFlagRadioGroup(defaultValue: TestPetType.cat, key: "pet_radio_key")
        XCTAssertEqual(radio.wrappedValue, .cat)
    }

    func testRadioGroupWrappedValueReflectsProviderOverride() {
        let radio = FeatureFlagRadioGroup(defaultValue: TestPetType.cat, key: "pet_radio_key")
        mockProvider.set(value: TestPetType.dog, for: "pet_radio_key")
        XCTAssertEqual(radio.wrappedValue, .dog)
    }

    func testRadioGroupPListElements() {
        let radio = FeatureFlagRadioGroup(defaultValue: TestPetType.cat, key: "pet_radio_key")
        XCTAssertEqual(radio.pListElements.count, 1)
    }

    // MARK: - FeatureFlagSlider

    func testSliderWrappedValueDefault() {
        let slider = FeatureFlagSlider(defaultValue: 5, key: "slider_key", range: 0...10)
        XCTAssertEqual(slider.wrappedValue, 5)
    }

    func testSliderWrappedValueReflectsProviderOverride() {
        let slider = FeatureFlagSlider(defaultValue: 5, key: "slider_key", range: 0...10)
        mockProvider.set(value: 8, for: "slider_key")
        XCTAssertEqual(slider.wrappedValue, 8)
    }

    func testSliderPListElementsIncludesGroupTitleAndSlider() {
        let slider = FeatureFlagSlider(defaultValue: 5, key: "slider_key", range: 0...10)
        XCTAssertEqual(slider.pListElements.count, 3)
    }

    func testSliderPListElementsEmptyWithoutRange() {
        let slider = FeatureFlagSlider(defaultValue: 5, keys: [ProviderKey(provider: .developmentLocal, key: "slider_key")])
        XCTAssertTrue(slider.pListElements.isEmpty)
    }

    func testSliderKeyToTitle() {
        let slider = FeatureFlagSlider(defaultValue: 5, key: "example_key_enabled", range: 0...10)
        XCTAssertEqual(slider.keyToTitle("example_key_enabled"), "Example Key")
    }

    func testSliderDefaultFooterText() {
        let slider = FeatureFlagSlider(defaultValue: 5, key: "slider_key", range: 0...10)
        XCTAssertEqual(slider.footerText, "Default value: 5")
    }

    // MARK: - FeatureFlagTitle

    func testTitleWrappedValueDefault() {
        let title = FeatureFlagTitle(defaultValue: true, key: "title_key", title: "My Title")
        XCTAssertTrue(title.wrappedValue)
    }

    func testTitleWrappedValueReflectsProviderOverride() {
        let title = FeatureFlagTitle(defaultValue: true, key: "title_key", title: "My Title")
        mockProvider.set(value: false, for: "title_key")
        XCTAssertFalse(title.wrappedValue)
    }

    func testTitlePListElements() {
        let title = FeatureFlagTitle(defaultValue: true, key: "title_key", title: "My Title")
        XCTAssertEqual(title.pListElements.count, 1)
    }

    // MARK: - FeatureFlagTextField

    func testTextFieldWrappedValueDefault() {
        let field = FeatureFlagTextField(keys: [ProviderKey(provider: .developmentLocal, key: "text_key")], title: nil, defaultValue: "hello")
        XCTAssertEqual(field.wrappedValue, "hello")
    }

    func testTextFieldWrappedValueSetterWritesThroughService() {
        var field = FeatureFlagTextField(keys: [ProviderKey(provider: .developmentLocal, key: "text_key")], title: nil, defaultValue: "hello")
        field.wrappedValue = "world"
        XCTAssertEqual(field.wrappedValue, "world")
    }

    func testTextFieldPListElements() {
        let field = FeatureFlagTextField(keys: [ProviderKey(provider: .developmentLocal, key: "text_key")], title: "Text", defaultValue: "hello")
        XCTAssertEqual(field.pListElements.count, 1)
    }

    // MARK: - FeatureFlagGroup

    func testGroupWrappedValueFromWrappedValueInit() {
        let group = FeatureFlagGroup(wrappedValue: "Section")
        XCTAssertEqual(group.wrappedValue, "Section")
    }

    func testGroupConvenienceInit() {
        let group = FeatureFlagGroup("Section", footer: "Footer text")
        XCTAssertEqual(group.wrappedValue, "Section")
        XCTAssertEqual(group.footerText, "Footer text")
    }

    func testGroupPListElements() {
        let group = FeatureFlagGroup("Section", footer: "Footer text")
        XCTAssertEqual(group.pListElements.count, 1)
    }

    // MARK: - FeatureFlagChildPane

    private struct AdvancedSettings: Equatable {
        let value = 1
    }

    func testChildPaneWrappedValueHoldsTheChildFlags() {
        let pane = FeatureFlagChildPane(wrappedValue: AdvancedSettings(), "Advanced")
        XCTAssertEqual(pane.wrappedValue, AdvancedSettings())
    }

    func testChildPaneFilenameDefaultsToTheWrappedTypesName() {
        let pane = FeatureFlagChildPane(wrappedValue: AdvancedSettings(), "Advanced")
        XCTAssertEqual(pane.filename, "AdvancedSettings")
    }

    func testChildPaneFilenameCanBeOverridden() {
        let pane = FeatureFlagChildPane(wrappedValue: AdvancedSettings(), "Advanced", filename: "custom_filename")
        XCTAssertEqual(pane.filename, "custom_filename")
    }

    func testChildPanePListElements() {
        let pane = FeatureFlagChildPane(wrappedValue: AdvancedSettings(), "Advanced")
        XCTAssertEqual(pane.pListElements.count, 1)
    }

    func testChildPaneSubFileFeatureFlagsExposesWrappedValue() {
        let pane = FeatureFlagChildPane(wrappedValue: AdvancedSettings(), "Advanced")
        XCTAssertEqual(pane.subFileFeatureFlags as? AdvancedSettings, AdvancedSettings())
    }

    /// The generator (in `ScriptMain.swift`, which can't itself be unit tested — it
    /// references a `FeatureFlags` type that only exists in a consumer project) discovers
    /// child panes by `Mirror`-walking the root struct for `PListSubFileProviding`. This
    /// verifies that discovery mechanism works against a real property-wrapped struct.
    func testChildPaneDiscoverableViaMirrorOnParentStruct() {
        struct RootFlags {
            @FeatureFlagChildPane("Advanced")
            var advanced = AdvancedSettings()
        }

        let childPanes = Mirror(reflecting: RootFlags()).children.compactMap { $1 as? PListSubFileProviding }

        XCTAssertEqual(childPanes.count, 1)
        XCTAssertEqual(childPanes.first?.filename, "AdvancedSettings")
        XCTAssertEqual(childPanes.first?.subFileFeatureFlags as? AdvancedSettings, AdvancedSettings())
    }

    // MARK: - FeatureFlagReset

    func testResetWrappedValueDefaultIsFalse() {
        let reset = FeatureFlagReset(key: "reset_key", resetKeys: [])
        XCTAssertFalse(reset.wrappedValue)
    }

    func testResetPListElementsWithoutTitle() {
        let reset = FeatureFlagReset(key: "reset_key", resetKeys: [])
        XCTAssertEqual(reset.pListElements.count, 1)
    }

    func testResetDefaultType() {
        let reset = FeatureFlagReset(key: "reset_key", resetKeys: [])
        XCTAssertEqual(reset.defaultType, "Bool")
    }
}
