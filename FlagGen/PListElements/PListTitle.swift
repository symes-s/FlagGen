//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

// swiftlint:disable line_length
/// [Apple Documentation](https://developer.apple.com/library/archive/documentation/PreferenceSettings/Conceptual/SettingsApplicationSchemaReference/Articles/PSTitleValueSpecifier.html#//apple_ref/doc/uid/TP40007015-SW1)
///
/// This element represents a read-only preference. You can use it to provide the user with information about your app’s configuration.
///
public struct PListTitle<T: RawRepresentable & Encodable>: PListValueElement where T.RawValue: Encodable {
    let title: String?
    let key: String
    var type: String { "PSTitleValueSpecifier" }
    var defaultValue: T.RawValue
    var `default`: T { T.init(rawValue: defaultValue)! }
    let keys: [String: T]?

    init(key: String, title: String?, defaultValue: T, keys: [String: T]?) {
        self.title = title
        self.key = key
        self.defaultValue = defaultValue.rawValue
        self.keys = keys
    }

    enum CodingKeys: String, CodingKey {
        case defaultValue = "DefaultValue"
        case key = "Key"
        case title = "Title"
        case type = "Type"
        case titles = "Titles"
        case values = "Values"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(defaultValue)", forKey: .defaultValue)
        try container.encode(key, forKey: .key)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(type, forKey: .type)
        if let keys {
            try container.encode(Array(keys.keys), forKey: .titles)
            try container.encode(Array(keys.values), forKey: .values)
        }
    }
}
// swiftlint:enable line_length

public struct PListBasicTitle<T: Encodable>: PListElement {
    let title: String?
    let key: String
    let defaultValue: T
    let keys: [String: T]?
    var type: String { "PSTitleValueSpecifier" }

    init(key: String, title: String?, defaultValue: T, keys: [String: T]? = nil) {
        self.title = title
        self.key = key
        self.defaultValue = defaultValue
        self.keys = keys
    }

    enum CodingKeys: String, CodingKey {
        case defaultValue = "DefaultValue"
        case key = "Key"
        case title = "Title"
        case type = "Type"
        case titles = "Titles"
        case values = "Values"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(defaultValue)", forKey: .defaultValue)
        try container.encode(key, forKey: .key)
        try container.encodeIfPresent(title, forKey: .title) // Required
        try container.encode(type, forKey: .type)
        if let keys {
            try container.encode(Array(keys.keys), forKey: .titles)
            try container.encode(Array(keys.values), forKey: .values)
        }
    }

    var defaultDescription: String? { nil }
}
