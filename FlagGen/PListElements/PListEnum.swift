//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

public struct PListEnum<T: PListMultiValueDefining>: PListValueElement {
    let title: String?
    let key: String
    let options: [PListMultiValueElement<T>]
    var type: String { "PSMultiValueSpecifier" }
    var defaultValue: T.RawValue { options.first(where: { $0.isDefault })!.value }
    var `default`: T { T.init(rawValue: defaultValue)! }

    init(key: String, title: String, defaultValue: T) {
        self.key = key
        self.title = title
        self.options = T.pListValues(defaultValue: defaultValue)
    }

    enum CodingKeys: String, CodingKey {
        case defaultValue = "DefaultValue"
        case key = "Key"
        case title = "Title"
        case type = "Type"
        case titles = "Titles"
        case values = "Values"
        case shortTitles = "ShortTitles"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(key, forKey: .key)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(options.map({ $0.title }), forKey: .titles)
        try container.encode(options.map({ $0.value }), forKey: .values)
        try container.encodeIfPresent(options.compactMap({ $0.shortTitle }), forKey: .shortTitles)
    }
}

// used in array in `PListEnum`
public struct PListMultiValueElement<T: RawRepresentable> where T.RawValue: Encodable {
    let value: T.RawValue
    let isDefault: Bool
    let title: String
    let shortTitle: String?
}
