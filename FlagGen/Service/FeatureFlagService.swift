//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

/// A Service that backs @FeatureFlag information
public final class FeatureFlagService: @unchecked Sendable {
    public static let `default` = FeatureFlagService()
    init() { }

    private let lock = NSLock()
    private var _providers: [FeatureFlagProvider] = []

    /// An atomic snapshot, safe to iterate without holding `lock`.
    private func snapshotProviders() -> [FeatureFlagProvider] {
        lock.lock()
        defer { lock.unlock() }
        return _providers
    }

    /// Runs `body` — a mutation or assignment against `_providers` — under a single lock
    /// acquisition, so a compound operation like `append` can't race with a concurrent
    /// mutation and silently lose an update. `@autoclosure` defers evaluating `body` until
    /// after the lock is held, without callers needing to name `_providers` as a parameter.
    @discardableResult
    private func mutateProviders<T>(_ body: @autoclosure () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    /// Exposed for tests verifying registrations survive concurrent access.
    var providerCount: Int {
        snapshotProviders().count
    }

    func get<T: RawRepresentable>(keys: [ProviderKey], defaultValue: T) -> T {
        // Find first value from providers with matching type
        if let value: T = snapshotProviders().compactMap({ $0.get(keys: keys) }).first {
            return value
        }

        // For physical devices, the plist entry for the UserDefault won't exist unless it's written first
        // Then the Settings toggle will have no effect.
        // This issue doesn't affect the simulator
        #if !targetEnvironment(simulator)
        set(keys: keys, value: defaultValue)
        #endif

        // otherwise return the defaultValue
        return defaultValue
    }

    func set<T: RawRepresentable>(keys: [ProviderKey], value: T) {
        let providers = snapshotProviders()
        keys.forEach { key in
            providers.filter { $0.type == key.provider }.forEach { $0.set(value: value, for: key.key) }
        }
    }

    public func registerProvider(_ provider: FeatureFlagProvider) {
        mutateProviders(_providers.append(provider))
    }

    public func setProviders(_ providerList: [FeatureFlagProvider]) {
        mutateProviders(_providers = providerList)
    }

    func resetLocal(_ key: String) {
        guard let provider = snapshotProviders().first(where: { $0.type == .developmentLocal }) else { return }
        provider.reset(key: key)
    }

    func reset(keys: [ProviderKey]) {
        let providers = snapshotProviders()
        for key in keys {
            for provider in providers {
                if key.provider.name != provider.type.name { continue }
                provider.reset(key: key.key)
            }
        }
    }

    func reset(rawKeys: [String]) {
        let providers = snapshotProviders()
        for key in rawKeys {
            for provider in providers {
                provider.reset(key: key)
            }
        }
    }

    func publisher<T: RawRepresentable>(for key: ProviderKey) -> AnyPublisher<T?, Never> {
        let provider = snapshotProviders()
            .filter { $0.type == key.provider }
            .compactMap { $0 as? (any FeatureFlagProviderInternal) }
            .first
        guard let provider else { return Just<T?>(nil).eraseToAnyPublisher() }

        return provider.publisher(for: key.key)
    }

    func publisher<T: RawRepresentable>(for keys: [ProviderKey]) -> AnyPublisher<T?, Never> {
        guard let localKey = keys.first(where: { $0.provider == .developmentLocal }) else {
            return Just<T?>(nil).eraseToAnyPublisher()
        }
        let provider = snapshotProviders()
            .filter { $0.type == localKey.provider }
            .compactMap { $0 as? any FeatureFlagProviderInternal }
            .first
        guard let provider else {
            return Just<T?>(nil).eraseToAnyPublisher()
        }

        return provider.publisher(for: localKey.key)
    }
}
