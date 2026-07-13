//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

// swiftlint:disable:next line_length
/// [Apple Documentation](https://developer.apple.com/library/archive/documentation/PreferenceSettings/Conceptual/SettingsApplicationSchemaReference/Articles/RadioGroupElement.html#//apple_ref/doc/uid/TP30915196-SW2)
public struct PListRadioGroup<T: PListMultiValueDefining>: PListValueElement {
    let title: String?
    let footer: String?
    let key: String
    let options: [PListMultiValueElement<T>]
    var type: String { "PSRadioGroupSpecifier" }
    var defaultValue: T.RawValue { options.first(where: { $0.isDefault })!.value }
    var `default`: T { T.init(rawValue: defaultValue)! }
    let sortByTitle: Bool

    init(
        key: String,
        title: String,
        defaultValue: T,
        footer: String?,
        sortByTitle: Bool
    ) {
        self.key = key
        self.title = title
        self.footer = footer
        self.sortByTitle = sortByTitle
        self.options = T.pListValues(defaultValue: defaultValue)
    }

    enum CodingKeys: String, CodingKey {
        case defaultValue = "DefaultValue"
        case key = "Key"
        case title = "Title"
        case type = "Type"
        case titles = "Titles"
        case values = "Values"
        case footer = "FooterText"
        case sortByTitle = "DisplaySortedByTitle"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(key, forKey: .key)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(footer, forKey: .footer)
        try container.encode(type, forKey: .type)
        try container.encode(options.map({ $0.title }), forKey: .titles)
        try container.encode(options.map({ $0.value }), forKey: .values)
        if sortByTitle {
            try container.encode(sortByTitle, forKey: .sortByTitle)
        }
    }
}
