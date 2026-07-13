//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

final class PListElementsTests: XCTestCase {
    private func decode(_ element: PListElement) throws -> [String: Any] {
        let data = try element.encoded()
        let object = try JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }

    // MARK: - PListToggle

    func testPListToggleEncoding() throws {
        let toggle = PListToggle(key: "flag_enabled", title: "My Flag", defaultValue: true)
        let json = try decode(toggle)
        XCTAssertEqual(json["Key"] as? String, "flag_enabled")
        XCTAssertEqual(json["Title"] as? String, "My Flag")
        XCTAssertEqual(json["DefaultValue"] as? Bool, true)
        XCTAssertEqual(json["Type"] as? String, "PSToggleSwitchSpecifier")
    }

    func testPListToggleSynthesizesTitleFromKey() throws {
        let toggle = PListToggle(key: "example_flag_enabled", defaultValue: false)
        let json = try decode(toggle)
        XCTAssertEqual(json["Title"] as? String, "Example Flag")
    }

    func testPListToggleDefaultDescription() {
        let toggle = PListToggle(key: "flag_enabled", defaultValue: true)
        XCTAssertEqual(toggle.defaultDescription, "true")
    }

    // MARK: - PListGroup

    func testPListGroupEncoding() throws {
        let group = PListGroup(title: "Section", footerText: "Footer")
        let json = try decode(group)
        XCTAssertEqual(json["Title"] as? String, "Section")
        XCTAssertEqual(json["FooterText"] as? String, "Footer")
        XCTAssertEqual(json["Type"] as? String, "PSGroupSpecifier")
    }

    func testPListGroupOmitsNilTitleAndFooter() throws {
        let group = PListGroup(title: nil, footerText: nil)
        let json = try decode(group)
        XCTAssertNil(json["Title"])
        XCTAssertNil(json["FooterText"])
        XCTAssertNil(group.defaultDescription)
    }

    // MARK: - PListChildPane

    func testPListChildPaneEncoding() throws {
        let pane = PListChildPane(title: "Advanced", file: "advanced")
        let json = try decode(pane)
        XCTAssertEqual(json["Title"] as? String, "Advanced")
        XCTAssertEqual(json["File"] as? String, "advanced")
        XCTAssertEqual(json["Type"] as? String, "PSChildPaneSpecifier")
        XCTAssertNil(pane.defaultDescription)
    }

    // MARK: - PListTextField

    func testPListTextFieldEncoding() throws {
        let field = PListTextField(title: "Name", key: "name_key", defaultValue: "Bob")
        let json = try decode(field)
        XCTAssertEqual(json["DefaultValue"] as? String, "Bob")
        XCTAssertEqual(json["Type"] as? String, "PSTextFieldSpecifier")
    }

    func testPListTextFieldEncodesEmptyStringForNilDefault() throws {
        let field = PListTextField(title: nil, key: "name_key", defaultValue: nil)
        let json = try decode(field)
        XCTAssertEqual(json["DefaultValue"] as? String, "")
    }

    // MARK: - PListSlider

    func testPListSliderEncoding() throws {
        let slider = PListSlider(key: "slider_key", defaultValue: 5, range: 0...10)
        let json = try decode(slider)
        XCTAssertEqual(json["Key"] as? String, "slider_key")
        XCTAssertEqual(json["DefaultValue"] as? Int, 5)
        XCTAssertEqual(json["MinimumValue"] as? Int, 0)
        XCTAssertEqual(json["MaximumValue"] as? Int, 10)
        XCTAssertEqual(json["Type"] as? String, "PSSliderSpecifier")
    }

    // MARK: - PListTitle / PListBasicTitle

    func testPListTitleEncoding() throws {
        let title = PListTitle(key: "pet_key", title: "Pet", defaultValue: TestPetType.cat, keys: nil)
        let json = try decode(title)
        XCTAssertEqual(json["DefaultValue"] as? String, "cat")
        XCTAssertEqual(json["Title"] as? String, "Pet")
        XCTAssertEqual(json["Type"] as? String, "PSTitleValueSpecifier")
        XCTAssertNil(json["Titles"])
    }

    func testPListBasicTitleEncoding() throws {
        let title = PListBasicTitle(key: "count_key", title: "Count", defaultValue: 5)
        let json = try decode(title)
        XCTAssertEqual(json["DefaultValue"] as? String, "5")
        XCTAssertEqual(json["Key"] as? String, "count_key")
        XCTAssertNil(title.defaultDescription)
    }

    // MARK: - PListEnum

    func testPListEnumEncoding() throws {
        let entry = PListEnum(key: "pet_key", title: "Pet Type", defaultValue: TestPetType.cat)
        let json = try decode(entry)
        XCTAssertEqual(json["DefaultValue"] as? String, "cat")
        XCTAssertEqual(json["Type"] as? String, "PSMultiValueSpecifier")

        let values = json["Values"] as? [String]
        XCTAssertEqual(Set(values ?? []), Set(["cat", "dog"]))

        let titles = json["Titles"] as? [String]
        XCTAssertEqual(Set(titles ?? []), Set(["Haughty Cat", "Scruffy Dog"]))

        let shortTitles = json["ShortTitles"] as? [String]
        XCTAssertEqual(Set(shortTitles ?? []), Set(["Cat", "Dog"]))
    }

    // MARK: - PListRadioGroup

    func testPListRadioGroupEncoding() throws {
        let entry = PListRadioGroup(key: "pet_key", title: "Pet Type", defaultValue: TestPetType.dog, footer: "Choose one", sortByTitle: true)
        let json = try decode(entry)
        XCTAssertEqual(json["DefaultValue"] as? String, "dog")
        XCTAssertEqual(json["FooterText"] as? String, "Choose one")
        XCTAssertEqual(json["Type"] as? String, "PSRadioGroupSpecifier")
        XCTAssertEqual(json["DisplaySortedByTitle"] as? Bool, true)
    }

    func testPListRadioGroupOmitsSortFlagWhenFalse() throws {
        let entry = PListRadioGroup(key: "pet_key", title: "Pet Type", defaultValue: TestPetType.dog, footer: nil, sortByTitle: false)
        let json = try decode(entry)
        XCTAssertNil(json["DisplaySortedByTitle"])
        XCTAssertNil(json["FooterText"])
    }
}
