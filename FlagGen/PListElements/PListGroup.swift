//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

struct PListGroup: PListElement {
    let title: String?
    let footerText: String?
    var type: String { "PSGroupSpecifier" }

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case type = "Type"
        case footerText = "FooterText"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(footerText, forKey: .footerText)
    }

    var defaultDescription: String? { nil }
}
