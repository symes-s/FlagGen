//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

final class UserDefaultsFeatureFlagStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "com.flaggen.tests.store.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - get / set / reset

    func testSetAndGetBool() {
        defaults.set(value: true, for: "flag")
        let result: Bool? = defaults.get(key: "flag")
        XCTAssertEqual(result, true)
    }

    func testGetReturnsNilForMissingKey() {
        let result: Bool? = defaults.get(key: "missing")
        XCTAssertNil(result)
    }

    func testSetAndGetCustomStringBackedEnum() {
        defaults.set(value: TestPetType.dog, for: "pet")
        let result: TestPetType? = defaults.get(key: "pet")
        XCTAssertEqual(result, .dog)
    }

    func testSetAndGetCustomIntBackedEnum() {
        defaults.set(value: TestPriority.high, for: "priority")
        let result: TestPriority? = defaults.get(key: "priority")
        XCTAssertEqual(result, .high)
    }

    func testGetReturnsNilWhenStoredRawValueDoesNotMatchType() {
        defaults.set(42, forKey: "pet")
        let result: TestPetType? = defaults.get(key: "pet")
        XCTAssertNil(result)
    }

    func testGetReturnsNilWhenRawValueIsInvalidCase() {
        defaults.set("bird", forKey: "pet")
        let result: TestPetType? = defaults.get(key: "pet")
        XCTAssertNil(result)
    }

    func testResetRemovesValue() {
        defaults.set(value: true, for: "flag")
        defaults.reset(key: "flag")
        let result: Bool? = defaults.get(key: "flag")
        XCTAssertNil(result)
    }

    // MARK: - observe

    func testObserveEmitsConvertedCustomEnumOnChange() {
        var received: [TestPetType?] = []
        let observer = defaults.observe(key: "pet") { (value: TestPetType?) in
            received.append(value)
        }
        defaults.set(value: TestPetType.cat, for: "pet")

        XCTAssertEqual(received, [.cat])
        withExtendedLifetime(observer) {}
    }

    func testObserveEmitsNilWhenStoredRawValueDoesNotMatchType() {
        var received: [TestPetType?] = []
        let observer = defaults.observe(key: "pet") { (value: TestPetType?) in
            received.append(value)
        }
        defaults.set(99, forKey: "pet")

        XCTAssertEqual(received, [nil])
        withExtendedLifetime(observer) {}
    }

    func testObserveEmitsBoolOnChange() {
        var received: [Bool?] = []
        let observer = defaults.observe(key: "flag") { (value: Bool?) in
            received.append(value)
        }
        defaults.set(value: false, for: "flag")

        XCTAssertEqual(received, [false])
        withExtendedLifetime(observer) {}
    }

    func testObserveEmitsNilAfterReset() {
        defaults.set(value: true, for: "flag")
        var received: [Bool?] = []
        let observer = defaults.observe(key: "flag") { (value: Bool?) in
            received.append(value)
        }
        defaults.reset(key: "flag")

        XCTAssertEqual(received, [nil])
        withExtendedLifetime(observer) {}
    }
}
