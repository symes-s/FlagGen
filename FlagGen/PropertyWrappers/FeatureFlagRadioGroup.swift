//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

@propertyWrapper
public struct FeatureFlagRadioGroup<T: PListMultiValueDefining>: PListElementProviding, FeatureFlagKeysProviding {

    public var wrappedValue: T {
        let value = FeatureFlagService.default.get(keys: keys, defaultValue: defaultValue)
        return value
    }

    public var projectedValue: FeatureFlagRadioGroup<T> { self }

    let pListEntry: PListRadioGroup<T>
    public let keys: [ProviderKey]

    var defaultValue: T {
        pListEntry.default
    }

    public var publisher: AnyPublisher<T?, Never> {
        FeatureFlagService.default.publisher(for: keys)
            .map { (value: T?) -> T in
                guard let value else {
                    return defaultValue
                }
                return value
            }
            .eraseToAnyPublisher()
    }

    public init(defaultValue: T, key: String, footer: String? = nil, sortByTitle: Bool = true) {
        self.pListEntry = T.pListRadioGroupEntry(
            key: key,
            defaultValue: defaultValue,
            footer: footer,
            sortByTitle: sortByTitle
        )
        self.keys = [ProviderKey(provider: .developmentLocal, key: key)]
    }

    var pListElements: [PListElement] {
        [pListEntry]
    }

    var defaultType: String {
        "\(type(of: defaultValue))"
    }
}
