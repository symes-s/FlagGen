//
//  FlagGen
//  Created by Scott Symes
//

import XCTest
@testable import FlagGen

final class ProviderTypeTests: XCTestCase {
    func testNameDescribesCase() {
        XCTAssertEqual(ProviderType.developmentLocal.name, "developmentLocal")
    }

    func testEquatable() {
        XCTAssertEqual(ProviderType.developmentLocal, ProviderType.developmentLocal)
    }

    func testHashableUsableAsDictionaryKey() {
        let dict: [ProviderType: String] = [.developmentLocal: "value"]
        XCTAssertEqual(dict[.developmentLocal], "value")
    }

    func testProviderKeyStoresProviderAndKey() {
        let providerKey = ProviderKey(provider: .developmentLocal, key: "my_key")
        XCTAssertEqual(providerKey.provider, .developmentLocal)
        XCTAssertEqual(providerKey.key, "my_key")
    }

    // MARK: - Extensibility
    //
    // ProviderType is a struct specifically so consumers can add their own provider types
    // (e.g. a remote config service) without forking FlagGen — mirrors Notification.Name.

    func testConsumersCanDefineTheirOwnProviderType() {
        let custom = ProviderType(name: "mockRemote")
        XCTAssertEqual(custom.name, "mockRemote")
        XCTAssertNotEqual(custom, .developmentLocal)
    }

    func testCustomProviderTypesWithTheSameNameAreEqual() {
        XCTAssertEqual(ProviderType(name: "mockRemote"), ProviderType(name: "mockRemote"))
    }

    func testCustomProviderTypeUsableAsDictionaryKey() {
        let custom = ProviderType(name: "mockRemote")
        let dict: [ProviderType: String] = [.developmentLocal: "local", custom: "remote"]
        XCTAssertEqual(dict[.developmentLocal], "local")
        XCTAssertEqual(dict[custom], "remote")
    }
}
