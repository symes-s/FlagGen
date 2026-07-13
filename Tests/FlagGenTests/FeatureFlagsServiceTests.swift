//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
import Combine
@testable import FlagGen

class FeatureFlagsServiceTests: XCTestCase {

    // Local enum for testing
    private enum TestEnum: String {
        case `default` = "default"
        case value1 = "1"
        case value2 = "2"
    }

    func testRegisterProvider() throws {
        let service = FeatureFlagService()
        service.registerProvider(MockFeatureFlagProvider())
    }

    func testSetProviders() throws {
        let service = FeatureFlagService()
        service.setProviders([MockFeatureFlagProvider(), LocalProvider()])
    }

    func testGetFeatureFlag() throws {
        let provider = MockFeatureFlagProvider()
        provider.set(value: true, for: "test")

        let service = FeatureFlagService()
        service.registerProvider(provider)

        let result: Bool = service.get(key: "test", defaultValue: false)
        XCTAssertTrue(result)
        XCTAssertEqual(provider.lastKeyRequested, "test")

        provider.set(value: false, for: "test")
        XCTAssertFalse(service.get(key: "test", defaultValue: true))
    }

    func testGetFeatureFlagReturnsDefaultValueWithNoProviders() throws {
        let service = FeatureFlagService()
        service.setProviders([])

        let result: Bool = service.get(key: "test", defaultValue: true)
        XCTAssertTrue(result)
    }

    func testGetFeatureFlagReturnsDefaultValueWhenKeyNotPresent() throws {
        let provider = MockFeatureFlagProvider()

        let service = FeatureFlagService()
        service.registerProvider(provider)

        let result: Bool = service.get(key: "test", defaultValue: false)
        XCTAssertFalse(result)
        XCTAssertEqual(provider.lastKeyRequested, "test")
    }

    func testResetLocalCallsMatchingProviderReset() throws {
        let provider = MockFeatureFlagProvider()
        provider.set(value: true, for: "test")

        let service = FeatureFlagService()
        service.registerProvider(provider)

        service.resetLocal("test")

        let result: Bool? = provider.get(key: "test")
        XCTAssertNil(result)
    }

    func testResetLocalDoesNothingWhenNoLocalProviderRegistered() throws {
        let service = FeatureFlagService()
        service.resetLocal("test") // should not crash
    }

    func testResetKeysCallsMatchingProviderReset() throws {
        let provider = MockFeatureFlagProvider()
        provider.set(value: true, for: "test")

        let service = FeatureFlagService()
        service.registerProvider(provider)

        service.reset(keys: [ProviderKey(provider: .developmentLocal, key: "test")])

        let result: Bool? = provider.get(key: "test")
        XCTAssertNil(result)
    }

    func testResetRawKeysResetsAcrossAllProviders() throws {
        let providerA = MockFeatureFlagProvider()
        let providerB = MockFeatureFlagProvider()
        providerA.set(value: true, for: "test")
        providerB.set(value: true, for: "test")

        let service = FeatureFlagService()
        service.setProviders([providerA, providerB])

        service.reset(rawKeys: ["test"])

        let resultA: Bool? = providerA.get(key: "test")
        let resultB: Bool? = providerB.get(key: "test")
        XCTAssertNil(resultA)
        XCTAssertNil(resultB)
    }

    func testPublisherForProviderKeyReturnsNilWhenNoProviderRegistered() throws {
        let service = FeatureFlagService()
        let key = ProviderKey(provider: .developmentLocal, key: "test")

        let expectation = expectation(description: "publisher emits nil")
        let publisher: AnyPublisher<Bool?, Never> = service.publisher(for: key)
        let cancellable = publisher.sink { value in
            XCTAssertNil(value)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        cancellable.cancel()
    }

    func testPublisherForKeysReturnsNilWhenKeysEmpty() throws {
        let service = FeatureFlagService()
        service.registerProvider(LocalProvider())

        let expectation = expectation(description: "publisher emits nil")
        let publisher: AnyPublisher<Bool?, Never> = service.publisher(for: [])
        let cancellable = publisher.sink { value in
            XCTAssertNil(value)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        cancellable.cancel()
    }

    func testPublisherForProviderKeyEmitsConvertedCustomEnumValue() throws {
        let service = FeatureFlagService()
        service.registerProvider(LocalProvider())
        let key = "com.flaggen.tests.service.\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let providerKey = ProviderKey(provider: .developmentLocal, key: key)
        var received: [TestPetType?] = []
        let publisher: AnyPublisher<TestPetType?, Never> = service.publisher(for: providerKey)
        let cancellable = publisher.sink { received.append($0) }

        service.set(keys: [providerKey], value: TestPetType.dog)

        XCTAssertEqual(received, [nil, .dog])
        cancellable.cancel()
    }

    func testPublisherForKeysEmitsConvertedCustomEnumValue() throws {
        let service = FeatureFlagService()
        service.registerProvider(LocalProvider())
        let key = "com.flaggen.tests.service.\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }

        let keys = [ProviderKey(provider: .developmentLocal, key: key)]
        var received: [TestPetType?] = []
        let publisher: AnyPublisher<TestPetType?, Never> = service.publisher(for: keys)
        let cancellable = publisher.sink { received.append($0) }

        service.set(keys: keys, value: TestPetType.cat)

        XCTAssertEqual(received, [nil, .cat])
        cancellable.cancel()
    }

    func testConcurrentRegisterProviderDoesNotLoseRegistrations() {
        let service = FeatureFlagService()
        let iterations = 500

        // `registerProvider` compounds a read + append + write on the shared providers
        // array; without a lock around all three, concurrent calls can race and silently
        // drop an append when two threads' read-modify-write sequences interleave.
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            service.registerProvider(MockFeatureFlagProvider())
        }

        XCTAssertEqual(service.providerCount, iterations)
    }

    func testConcurrentRegisterSetProvidersAndGetDoesNotCrash() {
        let service = FeatureFlagService()

        DispatchQueue.concurrentPerform(iterations: 500) { index in
            switch index % 3 {
            case 0:
                service.registerProvider(MockFeatureFlagProvider())
            case 1:
                service.setProviders([MockFeatureFlagProvider()])
            default:
                _ = service.get(key: "concurrent_test", defaultValue: false)
            }
        }
    }
}

extension FeatureFlagService {
    func get<T: RawRepresentable>(key: String, defaultValue: T) -> T {
        return get(keys: [ProviderKey(provider: .developmentLocal, key: key)], defaultValue: defaultValue)
    }
}
