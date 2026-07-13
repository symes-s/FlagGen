//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

// Note. This is unused at the moment and untested. Ideally it should have a setter and getter
@propertyWrapper
public struct FeatureFlagTextField: PListElementProviding {
    public var wrappedValue: String {
        get {
            return FeatureFlagService.default.get(keys: keys, defaultValue: defaultValue)
        }
        set {
            FeatureFlagService.default.set(keys: keys, value: newValue)
        }
    }

    public var projectedValue: FeatureFlagTextField { self }

    public var publisher: AnyPublisher<String?, Never> {
        FeatureFlagService.default.publisher(for: keys)
    }

    public let keys: [ProviderKey]
    let title: String?
    let defaultValue: String

    public init(keys: [ProviderKey], title: String?, defaultValue: String) {
        self.keys = keys
        self.title = title
        self.defaultValue = defaultValue
    }

    var pListElements: [PListElement] {
        guard let key = keys.first(where: { $0.provider == .developmentLocal })?.key else { return [] }
        return [PListTextField(title: title, key: key, defaultValue: defaultValue)]
    }
}

extension String: @retroactive RawRepresentable {
    public var rawValue: String {
        self
    }

    public init?(rawValue: String) {
        self = rawValue
    }
}
