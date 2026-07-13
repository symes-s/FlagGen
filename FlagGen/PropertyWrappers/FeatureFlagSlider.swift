//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

public typealias FlagSlider = RawRepresentable & Comparable & Encodable & ExpressibleByIntegerLiteral & Equatable
typealias FlagSliderConformance = PListElementProviding & FeatureFlagKeysProviding & FeatureFlagDefaultValueProviding

@propertyWrapper
public struct FeatureFlagSlider<T: FlagSlider>: FlagSliderConformance where T.RawValue: Encodable & Equatable {
    public var wrappedValue: T {
        FeatureFlagService.default.get(keys: keys, defaultValue: defaultValue)
    }

    public var projectedValue: FeatureFlagSlider<T> { self }

    public var publisher: AnyPublisher<T, Never> {
        FeatureFlagService.default.publisher(for: keys)
            .map { (value: T?) -> T in
                guard let value else {
                    return self.defaultValue
                }
                return value
            }
            .eraseToAnyPublisher()
    }

    public let keys: [ProviderKey]
    public var defaultValue: T
    let range: ClosedRange<T>?
    let title: String?
    let footerText: String?

    /// To generate a matching PListSlider for debug purposes, specify a range and a `ProviderType.developmentLocal` key
    public init(
        defaultValue: T,
        keys: [ProviderKey],
        range: ClosedRange<T>? = nil,
        title: String? = nil,
        footerText: String? = nil
    ) {
        self.defaultValue = defaultValue
        self.keys = keys
        self.range = range
        self.title = title
        if let range {
            let rangeText = "[\(range.lowerBound) - \(range.upperBound)]"
            self.footerText = footerText ?? "Slider values in range: \(rangeText), Default value: \(defaultValue)"
        } else {
            self.footerText = nil
        }
    }

    public init(defaultValue: T, key: String, range: ClosedRange<T>, title: String? = nil, footerText: String? = nil) {
        self.defaultValue = defaultValue
        self.keys = [ProviderKey(provider: .developmentLocal, key: key)]
        self.range = range
        self.title = title
        // let rangeText = "[\(range.lowerBound) - \(range.upperBound)]"
        // self.footerText = footerText ?? "Slider values in range: \(rangeText), default value: \(defaultValue)"
        self.footerText = footerText ?? "Default value: \(defaultValue)"
    }

    var defaultType: String {
        "\(type(of: defaultValue))"
    }

    var pListElements: [PListElement] {
        if let range = range, let key = keys.first(where: { $0.provider == .developmentLocal })?.key {
            let psSlider = PListSlider(key: key, defaultValue: defaultValue, range: range)
            let title = title ?? keyToTitle(key)
            let psGroup = PListGroup(title: nil, footerText: footerText)
            let psTitle: PListBasicTitle<T>
            // if T.self == Double.self {
            //     psTitle = PListBasicTitle(key: key, title: title, defaultValue: defaultValue, keys: titleKeys())
            // } else {
                 psTitle = PListBasicTitle(key: key, title: title, defaultValue: defaultValue)
            // }
            return [psGroup, psTitle, psSlider]
        }
        return []
    }

    func keyToTitle(_ key: String) -> String {
        key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "enabled", with: "")
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }

    func titleKeys() -> [String: T]? {
        if let range = range as? ClosedRange<Double> {
            let exponentLow = Decimal(range.lowerBound).exponent
            let exponentHigh = Decimal(range.upperBound).exponent
            let exponent: Int
            if exponentLow >= 0, exponentHigh > 0 {
                exponent = max(exponentLow, exponentHigh)
            } else {
                exponent = min(exponentLow, exponentHigh)
            }
            let rangeDiff = range.upperBound - range.lowerBound
            let steps: Int = Int(rangeDiff / pow(10.0, Double(exponent)))
            var stepSize = (rangeDiff / Double(steps)) // .rounded()
            if exponent > 0 {
                stepSize = stepSize.rounded()
            }
            let format = exponent > 0 ? "%.0f" : "%.\(exponent.magnitude)f"
            var value = range.lowerBound
            var keys: [String: Double] = [:]
            keys[String(format: format, range.lowerBound)] = range.lowerBound
            for index in 1...steps {
                value = Double(index) * stepSize
                let string = String(format: format, value)
                keys[string] = value
            }
            keys[String(format: format, range.upperBound)] = range.upperBound
            return keys as? [String: T]
        } else {
            return [:]
        }
    }
}
