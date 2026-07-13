//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
import Combine
@testable import FlagGen

final class LocalProviderTests: XCTestCase {
    private var provider: LocalProvider!
    private var usedKeys: [String] = []
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        provider = LocalProvider()
        usedKeys = []
        cancellables = []
    }

    override func tearDown() {
        usedKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        usedKeys = []
        cancellables.removeAll()
        provider = nil
        super.tearDown()
    }

    private func uniqueKey(_ name: String) -> String {
        let key = "com.flaggen.tests.localprovider.\(name).\(UUID().uuidString)"
        usedKeys.append(key)
        return key
    }

    func testTypeIsDevelopmentLocal() {
        XCTAssertEqual(provider.type, .developmentLocal)
    }

    func testGetReturnsNilWhenNotSet() {
        let key = uniqueKey("bool")
        let result: Bool? = provider.get(key: key)
        XCTAssertNil(result)
    }

    func testSetAndGetBool() {
        let key = uniqueKey("bool")
        provider.set(value: true, for: key)
        XCTAssertEqual(provider.get(key: key), true)
    }

    func testSetAndGetCustomEnum() {
        let key = uniqueKey("pet")
        provider.set(value: TestPetType.dog, for: key)
        let result: TestPetType? = provider.get(key: key)
        XCTAssertEqual(result, .dog)
    }

    func testReset() {
        let key = uniqueKey("bool")
        provider.set(value: true, for: key)
        provider.reset(key: key)
        let result: Bool? = provider.get(key: key)
        XCTAssertNil(result)
    }

    func testPublisherEmitsInitialNilThenUpdatedBoolValue() {
        let key = uniqueKey("bool")
        var received: [Bool?] = []

        let publisher: AnyPublisher<Bool?, Never> = provider.publisher(for: key)
        publisher.sink { received.append($0) }.store(in: &cancellables)

        provider.set(value: true, for: key)

        XCTAssertEqual(received, [nil, true])
    }

    func testPublisherEmitsCurrentValueImmediatelyWhenAlreadySet() {
        let key = uniqueKey("bool")
        provider.set(value: true, for: key)

        var received: [Bool?] = []
        let publisher: AnyPublisher<Bool?, Never> = provider.publisher(for: key)
        publisher.sink { received.append($0) }.store(in: &cancellables)

        XCTAssertEqual(received, [true])
    }

    func testPublisherEmitsConvertedCustomEnumOnChange() {
        // Regression coverage: this exact pipeline used to silently emit `nil` on change
        // before `UserDefaultsObserver.convert` replaced the naive `as? T` cast.
        let key = uniqueKey("pet")
        var received: [TestPetType?] = []

        let publisher: AnyPublisher<TestPetType?, Never> = provider.publisher(for: key)
        publisher.sink { received.append($0) }.store(in: &cancellables)

        provider.set(value: TestPetType.cat, for: key)

        XCTAssertEqual(received, [nil, .cat])
    }
}
