//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

struct PListTextField: PListValueElement {
    typealias DataType = String?
    let title: String?
    let key: String
    let defaultValue: String?
    var type: String { "PSTextFieldSpecifier" }

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case key = "Key"
        case defaultValue = "DefaultValue"
        case type = "Type"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(key, forKey: .key)
        try container.encode(defaultValue ?? "", forKey: .defaultValue)
        try container.encode(type, forKey: .type)
    }
}
