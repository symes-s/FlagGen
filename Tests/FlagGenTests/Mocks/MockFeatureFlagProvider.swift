//
//  FlagGen
//  Created by Scott Symes
//

import Foundation
@testable import FlagGen

/// `FeatureFlagService` may call a registered provider's `get`/`set` concurrently from
/// multiple threads (see `FeatureFlagService`'s own locking), so this mock's storage needs
/// the same protection a real provider (e.g. `LocalProvider`'s `UserDefaults`) already gets
/// for free — otherwise concurrent access to `store` races and can crash.
class MockFeatureFlagProvider: FeatureFlagProvider {
    private let lock = NSLock()
    private var store: [String: Any] = [:]
    private var _lastKeyRequested: String?

    /// The type of this provider
    var type: ProviderType

    /// Used to check the last `key` queried
    var lastKeyRequested: String? {
        lock.lock()
        defer { lock.unlock() }
        return _lastKeyRequested
    }

    init(type: ProviderType = .developmentLocal) {
        self.type = type
    }

    func get<T>(key: String) -> T? where T: RawRepresentable {
        lock.lock()
        defer { lock.unlock() }
        _lastKeyRequested = key
        return store[key] as? T
    }

    func set<T>(value: T, for key: String) where T: RawRepresentable {
        lock.lock()
        defer { lock.unlock() }
        store[key] = value
    }

    func reset(key: String) {
        lock.lock()
        defer { lock.unlock() }
        store[key] = nil
    }
}
