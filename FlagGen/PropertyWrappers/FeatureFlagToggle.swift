//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

/// This property wrapper provides
///
/// - parameter key: The key used by `UserDefaults` to get/set the value
/// - parameter title: This can be synthesised from the key name (explained below), or provided.explicity
/// - parameter defaultValue: The default value for the toggle, if not already set
///
/// # Notes: #
/// ** `title` synthesis from `key`: ** If no `title` is provided, the title will be constructed from the `key`:
///     - underscores (`_`) will be replaced with space (` `)
///     - instances of `"enabled"` will be removed
///     - The Words Will Be Capitalised
///
@propertyWrapper
public struct FeatureFlagToggle: PListElementProviding, FeatureFlagKeysProviding, FeatureFlagDefaultValueProviding {
    public var wrappedValue: Bool {
        FeatureFlagService.default.get(keys: keys, defaultValue: defaultValue)
    }

    public var projectedValue: FeatureFlagToggle { self }

    public let keys: [ProviderKey]
    let title: String?
    public let defaultValue: Bool

    public var publisher: AnyPublisher<Bool, Never> {
        let publisher: AnyPublisher<Bool?, Never> = FeatureFlagService.default.publisher(for: keys)
        return publisher.map { value in
            guard let value else {
                return false
            }
            return value
        }
        .eraseToAnyPublisher()
    }

    /// Convenience initialiser - Single provider: local development provider
    public init(defaultValue: Bool, key: String, title: String? = nil) {
        let keys = [ProviderKey(provider: .developmentLocal, key: key)]
        self.init(defaultValue: defaultValue, keys: keys, title: title)
    }

    /// Convenience initialiser - Individual keys for each provider
    public init(defaultValue: Bool, keysDict: [ProviderType: String], title: String? = nil) {
        let keys = keysDict.map { ProviderKey(provider: $0.key, key: $0.value) }
        self.init(defaultValue: defaultValue, keys: keys, title: title)
    }

    /// Convenience initialiser - common key for multiple providers
    public init(defaultValue: Bool, key: String, providers: [ProviderType], title: String? = nil) {
        let providers = Set(providers) // remove dupes
        let keys = providers.map { ProviderKey(provider: $0, key: key) }
        self.init(defaultValue: defaultValue, keys: keys, title: title)
    }

    public init(defaultValue: Bool, keys: [ProviderKey], title: String? = nil) {
        self.keys = keys
        self.defaultValue = defaultValue
        self.title = title
    }

    var pListElements: [PListElement] {
        guard let localKey else { return [] }
        if let title = title {
            return [PListToggle(key: localKey, title: title, defaultValue: defaultValue)]
        } else {
            return [PListToggle(key: localKey, defaultValue: defaultValue)]
        }
    }

    private var localKey: String? {
        keys.first(where: { $0.provider == .developmentLocal })?.key
    }

    var defaultType: String {
        "\(type(of: defaultValue))"
    }
}
