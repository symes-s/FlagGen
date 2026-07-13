//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

/// Local `FeatureFlagProvider` that stores (and loads) flag state from `UserDefaults`
public final class LocalProvider: FeatureFlagProviderInternal {
    public let type: ProviderType = .developmentLocal

    let store: ObservableFlagStore = UserDefaults.standard
    private var observers: Set<NSObject> = []
    @Published var allFlags: [String: Any] = [:]

    public init() { }

    public func get<T: RawRepresentable>(key: String) -> T? {
        let result: T? = store.get(key: key)
        return result
    }

    public func set<T>(value: T, for key: String) where T: RawRepresentable {
        store.set(value: value, for: key)
    }

    public func reset(key: String) {
        store.reset(key: key)
    }

    func publisher<T: RawRepresentable>(for key: String) -> AnyPublisher<T?, Never> {
        let currentValue: T? = store.get(key: key)
        let result = CurrentValueSubject<T?, Never>(currentValue)
        let observer = store.observe(key: key) { (value: T?) in
            result.send(value)
        }
        self.observers.insert(observer)
        return result.eraseToAnyPublisher()
    }
}
