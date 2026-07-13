//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

/// Protocol for defining sources of feature flags
///
/// Register a new `Provider` via `registerProvider` and `setProviders` on `FeatureFlagService`
public protocol FeatureFlagProvider {
    var type: ProviderType { get }

    func get<T: RawRepresentable & Sendable>(key: String) -> T?

    func set<T: RawRepresentable & Sendable>(value: T, for key: String)

    func reset(key: String)
}

protocol FeatureFlagProviderInternal: FeatureFlagProvider {
    associatedtype StoreType
    var store: StoreType { get }
    func publisher<T: RawRepresentable>(for key: String) -> AnyPublisher<T?, Never>
}

public extension FeatureFlagProvider {
    func contains<T: RawRepresentable>(key: String, type: T.Type) -> Bool {
        let value: T? = get(key: key)
        return value != nil
    }

    func contains<T: RawRepresentable>(keys: [ProviderKey], type: T.Type) -> Bool {
        guard let key = keys.first(where: { $0.provider == self.type })?.key else { return false }
        let value: T? = get(key: key)
        return value != nil
    }

    func get<T: RawRepresentable>(keys: [ProviderKey]) -> T? {
        guard let key = keys.first(where: { $0.provider == self.type })?.key else {
            return nil
        }
        let result: T? = get(key: key)
        return result
    }
}
