//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
import Combine
@testable import FlagGen

/// Exercises `@FeatureFlag*` publishers end-to-end through the real `LocalProvider` /
/// `UserDefaults` change-notification pipeline (rather than the in-memory mock), since that's the only
/// path that stresses the raw-value -> `RawRepresentable` conversion the observer fix
/// addresses.
final class PropertyWrapperPublisherTests: XCTestCase {
    private var localProvider: LocalProvider!
    private var usedKeys: [String] = []
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        localProvider = LocalProvider()
        FeatureFlagService.default.setProviders([localProvider])
        usedKeys = []
        cancellables = []
    }

    override func tearDown() {
        usedKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        usedKeys = []
        cancellables.removeAll()
        FeatureFlagService.default.setProviders([])
        localProvider = nil
        super.tearDown()
    }

    private func uniqueKey(_ name: String) -> String {
        let key = "com.flaggen.tests.wrapperpublisher.\(name).\(UUID().uuidString)"
        usedKeys.append(key)
        return key
    }

    func testToggleShouldPublishUpdatedValue() {
        let key = uniqueKey("toggle")
        let toggle = FeatureFlagToggle(defaultValue: false, key: key)
        var received: [Bool] = []
        toggle.publisher.sink { received.append($0) }.store(in: &cancellables)

        FeatureFlagService.default.set(keys: toggle.keys, value: true)

        XCTAssertEqual(received, [false, true])
    }

    func testEnumShouldPublishConvertedCustomEnumValue() {
        let key = uniqueKey("pet")
        let flag = FeatureFlagEnum(defaultValue: TestPetType.cat, key: key)
        var received: [TestPetType?] = []
        flag.publisher.sink { received.append($0) }.store(in: &cancellables)

        FeatureFlagService.default.set(keys: flag.keys, value: TestPetType.dog)

        XCTAssertEqual(received, [.cat, .dog])
    }

    func testRadioGroupShouldPublishConvertedCustomEnumValue() {
        let key = uniqueKey("pet_radio")
        let radio = FeatureFlagRadioGroup(defaultValue: TestPetType.cat, key: key)
        var received: [TestPetType?] = []
        radio.publisher.sink { received.append($0) }.store(in: &cancellables)

        FeatureFlagService.default.set(keys: radio.keys, value: TestPetType.dog)

        XCTAssertEqual(received, [.cat, .dog])
    }

    func testSliderShouldPublishUpdatedIntValue() {
        let key = uniqueKey("slider")
        let slider = FeatureFlagSlider(defaultValue: 5, key: key, range: 0...10)
        var received: [Int?] = []
        slider.publisher.sink { received.append($0) }.store(in: &cancellables)

        FeatureFlagService.default.set(keys: slider.keys, value: 8)

        XCTAssertEqual(received, [5, 8])
    }

    func testResetTogglesFlagBackToFalseAfterBeingEnabled() {
        let key = uniqueKey("reset")
        let reset = FeatureFlagReset(key: key, resetKeys: [])

        FeatureFlagService.default.set(keys: reset.keys, value: true)
        XCTAssertTrue(reset.wrappedValue)

        let expectation = expectation(description: "flag reset back to false")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)

        XCTAssertFalse(reset.wrappedValue)
    }

    func testResetAlsoResetsOtherSpecifiedKeysImmediatelyWhenEnabled() {
        // `resetKeys` are reset synchronously in the sink, unlike the flag's own key,
        // which only resets itself after the 0.5s delay.
        let resetKey = uniqueKey("reset")
        let otherKey = uniqueKey("other")

        localProvider.set(value: true, for: otherKey)
        XCTAssertEqual(localProvider.get(key: otherKey), true)

        let reset = FeatureFlagReset(key: resetKey, resetKeys: [otherKey])
        FeatureFlagService.default.set(keys: reset.keys, value: true)

        let result: Bool? = localProvider.get(key: otherKey)
        XCTAssertNil(result)
    }

    func testResetDoesNotResetItsOwnKeyWhenListedInResetKeys() {
        // The sink explicitly skips `localKey` inside the `resetKeys` loop, so listing
        // the flag's own key shouldn't reset it early (before the 0.5s delayed self-reset).
        let resetKey = uniqueKey("reset")
        let reset = FeatureFlagReset(key: resetKey, resetKeys: [resetKey])

        FeatureFlagService.default.set(keys: reset.keys, value: true)

        XCTAssertTrue(reset.wrappedValue)
    }
}
