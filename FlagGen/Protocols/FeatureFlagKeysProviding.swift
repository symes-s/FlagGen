//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

protocol FeatureFlagKeysProviding {
    var keys: [ProviderKey] { get }
    var defaultType: String { get }
}

public protocol FeatureFlagDefaultValueProviding {
    associatedtype DefaultValue: RawRepresentable where DefaultValue.RawValue: Encodable & Equatable
    associatedtype RawValue = DefaultValue.RawValue
    var defaultValue: DefaultValue { get }
}

extension FeatureFlagDefaultValueProviding {
    var defaultValueType: String {
        "\(type(of: defaultValue))"
    }

    var defaultValueString: String {
        "\(defaultValue)"
    }

    var defaultRawValueString: String {
        "\(defaultValue.rawValue)"
    }

    var rawValueType: String {
        "\(type(of: DefaultValue.RawValue.self))".replacingOccurrences(of: ".Type", with: "")
    }

    var defaultRawValue: DefaultValue.RawValue {
        defaultValue.rawValue
    }
}
