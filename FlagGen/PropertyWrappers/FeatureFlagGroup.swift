//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

/// Provides grouping of the elements in the plist
@propertyWrapper
public struct FeatureFlagGroup: PListElementProviding {
    public var wrappedValue: String?

    let footerText: String?

    public init(wrappedValue: String?) {
        self.wrappedValue = wrappedValue
        self.footerText = nil
    }

    public init(title: String?, footer: String?) {
        self.wrappedValue = title
        self.footerText = footer
    }

    public init(_ title: String, footer: String? = nil) {
        self.wrappedValue = title
        self.footerText = footer
    }

    var pListElements: [PListElement] {
        [PListGroup(title: wrappedValue, footerText: footerText)]
    }
}
