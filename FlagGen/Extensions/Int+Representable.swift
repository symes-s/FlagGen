//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

extension Int: @retroactive RawRepresentable {
    public typealias RawValue = Int
    public var rawValue: RawValue {
        self
    }

    public init?(rawValue: Self.RawValue) {
        self = rawValue
    }
}

extension Double: @retroactive RawRepresentable {
    public typealias RawValue = Double
    public var rawValue: RawValue {
        self
    }

    public init?(rawValue: Self.RawValue) {
        self = rawValue
    }
}
