// swiftlint:disable all
// Generated from the set of `FeatureFlagToggle`s and `FeatureFlagEnum`s in `FeatureFlags.swift`
// by `FlagGen`
//
// This file is required for UnitTest mocks
//
// - Do Not Edit -

#if canImport(FlagGen)
import FlagGen
#endif
import Foundation

public enum FeatureFlagsEnum: String, CaseIterable {
    case promoBanner = "promo_banner_enabled"
    case newArrivalBadge = "new_arrival_badge_enabled"
    case wishlistButton = "wishlist_button_enabled"
    case starRatings = "star_ratings_enabled"
    case checkoutType = "checkout_type"
}

extension FeatureFlagsEnum {
    public var localKey: String {
        self.rawValue
    }

    public var providerTypes: [ProviderType] {
        switch self {
        default: [.developmentLocal]
        }
    }

    public var keys: [ProviderKey] {
        [ProviderKey(provider: .developmentLocal, key: self.localKey)]
    }
}

extension FeatureFlagsEnum {
    public var valueType: Any.Type {
        switch self {
        case .checkoutType: CheckoutType.self
        default:            Bool.self
        }
    }
}
//swiftlint:enable all