//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

/// Identifies a source of feature flag values (local development overrides, a remote config
/// service, ...).
/// 
/// ```swift
/// extension ProviderType {
///     static let launchDarkly = ProviderType(name: "launchDarkly")
/// }
/// ```
/// See `Docs/CUSTOM_PROVIDERS.md` for a complete example wiring up LaunchDarkly or Firebase
public struct ProviderType: Sendable, Hashable {
    public let name: String

    public init(name: String) {
        self.name = name
    }

    /// Feature Flag only used for local development. Will only check local development providers.
    public static let developmentLocal = ProviderType(name: "developmentLocal")
}

public struct ProviderKey {
    public let provider: ProviderType
    public let key: String

    public init(provider: ProviderType, key: String) {
        self.provider = provider
        self.key = key
    }
}
