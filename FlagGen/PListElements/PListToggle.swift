//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

struct PListToggle: PListValueElement {
    typealias DataType = Bool
    let title: String?
    let key: String
    let defaultValue: Bool
    var type: String { "PSToggleSwitchSpecifier" }

    init(key: String, title: String, defaultValue: Bool) {
        self.key = key
        self.title = title
        self.defaultValue = defaultValue
    }

    init(key: String, defaultValue: Bool) {
        self.key = key
        self.title = key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "enabled", with: "")
            .trimmingCharacters(in: .whitespaces)
            .capitalized
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case defaultValue = "DefaultValue"
        case key = "Key"
        case title = "Title"
        case type = "Type"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(key, forKey: .key)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)
    }
}
