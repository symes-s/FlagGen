//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

public protocol PListMultiValueElementDefining: RawRepresentable where Self.RawValue: Encodable & Equatable {
    /// Displayed on second screen of Settings App
    var pListElementTitle: String { get }

    /// Displayed on primary screen of Settings App alongside title
    var pListElementShortTitle: String? { get }
}
