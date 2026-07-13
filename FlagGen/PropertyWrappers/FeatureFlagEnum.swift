//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

typealias FlagEnumConformance = PListElementProviding & FeatureFlagKeysProviding & FeatureFlagDefaultValueProviding

///
/// # Notes: #
/// 1. If Adding a new Feature Flag enum to `FeatureFlags.swift`,
///  please add the enum file to `FeatureFlags/Sources/FeatureFlags/FeatureFlagEnums/`
/// 2. Add an extension to the enum to conform to `PListEnumDefining`, i.e. `extension <enum-name>: PListEnumDefining {`
///
/// # Example propertyWrapper usage #
/// ```
/// @FeatureFlagEnum("config_doc_src", defaultValue: .onPremises)
/// public var forgerockConfig: ConfigDocumentSource
/// ```
/// # Example `PListEnumDefining` usage #
/// ```
/// enum PetType: String, CaseIterable {
///  case cat, dog
/// }
///
/// extension PetType: PListEnumDefining {
///
///   public static var pListTitle: String { "Type of pet to use" }
///
///   public var pListElementTitle: String {
///     switch self {
///     case .cat: return "Haughty Cat"
///     case .dog: return "Scruffy Dog"
///     }
///   }
///
///   public var pListElementShortTitle: String? {
///     switch self {
///     case .cat: return "Cat"
///     case .dog: return "Dog"
///     }
///   }
///
/// }
/// ```
@propertyWrapper
public struct FeatureFlagEnum<T: PListMultiValueDefining>: FlagEnumConformance {

    public var wrappedValue: T {
        let value = FeatureFlagService.default.get(keys: keys, defaultValue: defaultValue)
        return value
    }

    public var projectedValue: FeatureFlagEnum<T> { self }

    let pListEntry: PListEnum<T>
    public let keys: [ProviderKey]

    public var defaultValue: T {
        pListEntry.default
    }

    public var publisher: AnyPublisher<T, Never> {
        FeatureFlagService.default.publisher(for: keys)
            .map { (value: T?) -> T in
                guard let value else {
                    return defaultValue
                }
                return value
            }
            .eraseToAnyPublisher()
    }

    public init(defaultValue: T, key: String) {
        self.pListEntry = T.pListEnumEntry(key: key, defaultValue: defaultValue)
        self.keys = [ProviderKey(provider: .developmentLocal, key: key)]
    }

    var pListElements: [PListElement] {
        [pListEntry]
    }

    var defaultType: String {
        "\(type(of: defaultValue))"
    }
}
