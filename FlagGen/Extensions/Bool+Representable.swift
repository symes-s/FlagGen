//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

extension Bool: @retroactive RawRepresentable {
    public typealias RawValue = Bool

    public var rawValue: RawValue {
        self
    }

    public init?(rawValue: Self.RawValue) {
        self = rawValue
    }
}
