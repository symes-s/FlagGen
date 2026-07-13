//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

struct PListSlider<T: RawRepresentable & Comparable & Encodable>: PListValueElement {
    typealias DataType = T
    let title: String? = nil
    let key: String
    let defaultValue: T
    var type: String { "PSSliderSpecifier" }
    let range: ClosedRange<T>

    init(key: String, defaultValue: T, range: ClosedRange<T>) {
        self.key = key
        self.defaultValue = defaultValue
        self.range = range
    }

    enum CodingKeys: String, CodingKey {
        case defaultValue = "DefaultValue"
        case key = "Key"
        case type = "Type"
        case minValue = "MinimumValue"
        case maxValue = "MaximumValue"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(key, forKey: .key)
        try container.encode(type, forKey: .type)
        try container.encode(range.lowerBound, forKey: .minValue)
        try container.encode(range.upperBound, forKey: .maxValue)
    }
}
