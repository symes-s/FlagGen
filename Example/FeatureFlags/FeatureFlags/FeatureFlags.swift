//
//  FlagGen
//  Created by Scott Symes
//

#if canImport(FlagGen)
import FlagGen
#endif
import Foundation

public struct FeatureFlags {
    // If adding a new Feature Flag, run `swift package generate-feature-flags` from this
    // package's root. This will automatically add an entry to:
    // 1. `../Features.plist`
    // 2. `Generated/Enums/FeatureFlagsEnum.swift`
    //
    // ** Please commit these changes too **

    public static let `default`: FeatureFlags = FeatureFlags()
    init() { }

    @FeatureFlagToggle(defaultValue: true, key: "promo_banner_enabled")
    public var promoBannerEnabled

    @FeatureFlagToggle(defaultValue: false, key: "new_arrival_badge_enabled", title: "Show New Arrival Badge")
    public var newArrivalBadgeEnabled

    @FeatureFlagToggle(
        defaultValue: false,
        key: "wishlist_button_enabled",
        title: "Wish-list Button Enabled"
    )
    public var wishlistButtonEnabled

    @FeatureFlagToggle(defaultValue: false, key: "star_ratings_enabled")
    public var starRatingsEnabled

    // @FeatureFlagGroup
    // var checkoutTypeGroup = "Checkout Type"

    @FeatureFlagEnum(defaultValue: .standard, key: "checkout_type")
    public var checkoutType: CheckoutType
}
