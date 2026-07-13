//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

final class UserDefaultsObserverTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "com.flaggen.tests.observer.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - change-notification plumbing

    func testObserverFiresOnChangeWithRawStoredValueWhenSet() {
        var received: [Any] = []
        let observer = UserDefaultsObserver(key: "pet", userDefaults: defaults) { value in
            received.append(value)
        }
        defaults.set("cat", forKey: "pet")

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first as? String, "cat")
        withExtendedLifetime(observer) {}
    }

    func testObserverIgnoresChangesToOtherKeys() {
        var receivedCount = 0
        let observer = UserDefaultsObserver(key: "pet", userDefaults: defaults) { _ in
            receivedCount += 1
        }
        defaults.set("north", forKey: "direction")

        XCTAssertEqual(receivedCount, 0)
        withExtendedLifetime(observer) {}
    }

    func testObserverStopsFiringAfterBeingReleased() {
        var receivedCount = 0
        var observer: UserDefaultsObserver? = UserDefaultsObserver(key: "pet", userDefaults: defaults) { _ in
            receivedCount += 1
        }
        defaults.set("cat", forKey: "pet")
        XCTAssertEqual(receivedCount, 1)

        observer = nil
        defaults.set("dog", forKey: "pet")

        XCTAssertEqual(receivedCount, 1, "no further callbacks should fire once the observer has deinitialised")
    }

    // MARK: - convert

    func testConvertIdentityBool() {
        let result: Bool? = UserDefaultsObserver.convert(true)
        XCTAssertEqual(result, true)
    }

    func testConvertIdentityInt() {
        let result: Int? = UserDefaultsObserver.convert(42)
        XCTAssertEqual(result, 42)
    }

    func testConvertIdentityDouble() {
        let result: Double? = UserDefaultsObserver.convert(3.5)
        XCTAssertEqual(result, 3.5)
    }

    func testConvertIdentityString() {
        let result: String? = UserDefaultsObserver.convert("hello")
        XCTAssertEqual(result, "hello")
    }

    func testConvertCustomStringBackedEnumFromRawValue() {
        // This is exactly the case the old `new as? T` cast got wrong: UserDefaults hands back
        // the raw "cat" String, not a `TestPetType`.
        let result: TestPetType? = UserDefaultsObserver.convert("cat")
        XCTAssertEqual(result, .cat)
    }

    func testConvertCustomIntBackedEnumFromRawValue() {
        let result: TestPriority? = UserDefaultsObserver.convert(5)
        XCTAssertEqual(result, .medium)
    }

    func testConvertCustomEnumWithInvalidRawValueReturnsNil() {
        let result: TestPetType? = UserDefaultsObserver.convert("bird")
        XCTAssertNil(result)
    }

    func testConvertMismatchedTypeReturnsNil() {
        let result: TestPetType? = UserDefaultsObserver.convert(42)
        XCTAssertNil(result)
    }

    func testConvertNSNullReturnsNil() {
        let result: TestPetType? = UserDefaultsObserver.convert(NSNull())
        XCTAssertNil(result)
    }
}
