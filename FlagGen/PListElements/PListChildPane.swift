//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

// swiftlint:disable line_length
/*
 - ChildPane: https://developer.apple.com/library/archive/documentation/PreferenceSettings/Conceptual/SettingsApplicationSchemaReference/Articles/PSChildPaneSpecifier.html#//apple_ref/doc/uid/TP40007017-SW1
 - heirachy ref: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/Preferences/Preferences.html#//apple_ref/doc/uid/10000059i-CH6-SW4
 */
// swiftlint:enable line_length

struct PListChildPane: PListElement {
    let title: String?
    let file: String
    var type: String { "PSChildPaneSpecifier" }

    init(title: String?, file: String) {
        self.title = title
        self.file = file
    }

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case type = "Type"
        case file = "File"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(file, forKey: .file)
    }

    var defaultDescription: String? { nil }
}
