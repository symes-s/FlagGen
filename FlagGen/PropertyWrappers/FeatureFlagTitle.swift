//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

public typealias FlagTitleType = RawRepresentable & Encodable
typealias FlagTitleConformance = PListElementProviding & FeatureFlagKeysProviding

@propertyWrapper
public struct FeatureFlagTitle<T: FlagTitleType>: FlagTitleConformance where T.RawValue: Encodable {
    public var wrappedValue: T {
        let value = FeatureFlagService.default.get(keys: keys, defaultValue: defaultValue)
        return value
    }

    public var projectedValue: FeatureFlagTitle<T> { self }

    let pListEntry: PListTitle<T>
    public let keys: [ProviderKey]

    var defaultValue: T {
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

    public init(defaultValue: T, key: String, title: String?) {
        self.pListEntry = PListTitle(key: key, title: title, defaultValue: defaultValue, keys: nil)
        self.keys = [ProviderKey(provider: .developmentLocal, key: key)]
    }

    var pListElements: [PListElement] {
        [pListEntry]
    }

    var defaultType: String {
        "\(type(of: defaultValue))"
    }
}
