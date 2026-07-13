//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

/// This property wrapper provides
///
/// - parameter key: The key used by `UserDefaults` to get/set the value
/// - parameter title: This can be synthesised from the key name (explained below), or provided explicity
///
/// # Notes: #
/// ** `title` synthesis from `key`: ** If no `title` is provided, the title will be constructed from the `key`:
///     - underscores (`_`) will be replaced with space (` `)
///     - instances of `"enabled"` will be removed
///     - The Words Will Be Capitalised
///
///     The key-value oberver only works on physical devices, to the automated reset of the
///     toggle won't happen on the simulator
///
@propertyWrapper
public struct FeatureFlagReset: PListElementProviding, FeatureFlagKeysProviding, FeatureFlagDefaultValueProviding {
    public var wrappedValue: Bool {
        FeatureFlagService.default.get(keys: keys, defaultValue: defaultValue)
    }

    public let keys: [ProviderKey]
    private let resetKeys: [String]
    let title: String?
    public let defaultValue: Bool = false
    private var cancellable: AnyCancellable?

    var publisher: AnyPublisher<Bool, Never> {
        let publisher: AnyPublisher<Bool?, Never> = FeatureFlagService.default.publisher(for: keys)
        return publisher.map { value in
            guard let value else {
                return false
            }
            return value
        }
        .eraseToAnyPublisher()
    }

    public init(key: String, resetKeys: [String]) {
        let keys = [ProviderKey(provider: .developmentLocal, key: key)]
        self.init(keys: keys, resetKeys: resetKeys, title: nil)
    }

    /// Convenience initialiser - Single provider: local development provider
    public init(key: String, title: String?, resetKeys: [String]) {
        let keys = [ProviderKey(provider: .developmentLocal, key: key)]
        self.init(keys: keys, resetKeys: resetKeys, title: title)
    }

    public init(keys: [ProviderKey], resetKeys: [String], title: String? = nil) {
        self.keys = keys
        self.title = title
        self.resetKeys = resetKeys
        self.cancellable = self.publisher
            .sink { enabled in
                guard enabled else {
                    return
                }
                let localKey = keys.first(where: { $0.provider == .developmentLocal })
                // Reset all flags except this one
                for key in resetKeys {
                    guard key != localKey?.key else { continue }
                    FeatureFlagService.default.resetLocal(key)
                }
                let filtered = resetKeys.filter({ $0 != localKey?.key })
                FeatureFlagService.default.reset(rawKeys: filtered)

                // Delay and reset this flag
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let localKey {
                        FeatureFlagService.default.reset(keys: keys)
                        FeatureFlagService.default.resetLocal(localKey.key)
                    }
                }
            }
    }

    var pListElements: [PListElement] {
        guard let key = keys.first(where: { $0.provider == .developmentLocal })?.key else { return [] }
        if let title = title {
            return [PListToggle(key: key, title: title, defaultValue: defaultValue)]
        } else {
            return [PListToggle(key: key, defaultValue: defaultValue)]
        }
    }

    var defaultType: String {
        "\(type(of: defaultValue))"
    }
}
