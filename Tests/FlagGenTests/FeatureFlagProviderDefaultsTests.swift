//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

/// Covers the default implementations in the `FeatureFlagProvider` extension
/// (`contains`, `get(keys:)`), exercised via `MockFeatureFlagProvider`.
final class FeatureFlagProviderDefaultsTests: XCTestCase {
    func testContainsKeyReturnsFalseWhenAbsent() {
        let provider = MockFeatureFlagProvider()
        XCTAssertFalse(provider.contains(key: "missing", type: Bool.self))
    }

    func testContainsKeyReturnsTrueWhenPresent() {
        let provider = MockFeatureFlagProvider()
        provider.set(value: true, for: "flag")
        XCTAssertTrue(provider.contains(key: "flag", type: Bool.self))
    }

    func testContainsKeysReturnsTrueForMatchingProviderKey() {
        let provider = MockFeatureFlagProvider(type: .developmentLocal)
        provider.set(value: true, for: "flag")
        let keys = [ProviderKey(provider: .developmentLocal, key: "flag")]
        XCTAssertTrue(provider.contains(keys: keys, type: Bool.self))
    }

    func testContainsKeysReturnsFalseWhenNoKeysProvided() {
        let provider = MockFeatureFlagProvider(type: .developmentLocal)
        XCTAssertFalse(provider.contains(keys: [], type: Bool.self))
    }

    func testGetKeysReturnsValueForMatchingProviderKey() {
        let provider = MockFeatureFlagProvider(type: .developmentLocal)
        provider.set(value: TestPetType.dog, for: "pet")
        let keys = [ProviderKey(provider: .developmentLocal, key: "pet")]
        let result: TestPetType? = provider.get(keys: keys)
        XCTAssertEqual(result, .dog)
    }

    func testGetKeysReturnsNilWhenNoKeysProvided() {
        let provider = MockFeatureFlagProvider(type: .developmentLocal)
        let result: Bool? = provider.get(keys: [])
        XCTAssertNil(result)
    }

    func testResetClearsStoredValue() {
        let provider = MockFeatureFlagProvider()
        provider.set(value: true, for: "flag")
        provider.reset(key: "flag")
        let result: Bool? = provider.get(key: "flag")
        XCTAssertNil(result)
    }
}
