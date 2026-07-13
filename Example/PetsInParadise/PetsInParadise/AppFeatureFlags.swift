//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import FeatureFlags
import FlagGen
import Foundation

final class AppFeatureFlags: ObservableObject {
    static let shared = AppFeatureFlags()

    /// Promo banner at the top of the pet list.
    @Published var promoBannerEnabled: Bool = true

    /// "New Arrival" badge on recently added pets.
    @Published var newArrivalBadgeEnabled: Bool = true

    /// Heart button for adding a pet to the wishlist.
    @Published var wishlistButtonEnabled: Bool = true

    /// Star rating shown for each pet.
    @Published var starRatingsEnabled: Bool = true

    /// Checkout experience shown in the cart.
    @Published var checkoutType: CheckoutType = .standard

    private lazy var userDefaults: UserDefaults = .standard
    private var cancellables: Set<AnyCancellable> = []

    init() {
        FeatureFlagService.default.registerProvider(LocalProvider())
        updateValues()
        configureBindings()
    }

    func updateValues() {
        self.promoBannerEnabled = FeatureFlags.default.promoBannerEnabled
        self.newArrivalBadgeEnabled = FeatureFlags.default.newArrivalBadgeEnabled
        self.wishlistButtonEnabled = FeatureFlags.default.wishlistButtonEnabled
        self.starRatingsEnabled = FeatureFlags.default.starRatingsEnabled
        self.checkoutType = FeatureFlags.default.checkoutType
        print("""
        App Feature Flag Values updated.
        PromoBanner: \(promoBannerEnabled), NewArrivalBadge: \(newArrivalBadgeEnabled),
        WishListButton: \(wishlistButtonEnabled), StarRating: \(starRatingsEnabled), \
        CheckoutType: \(checkoutType)
        """)
    }

    // N.B. Publishers won't work in the simulator from different process (like Settings App)
    // call `updateValues()` in `SceneDelegate.sceneWillEnterForeground(scene:)` to refresh
    private func configureBindings() {
        FeatureFlags.default.$promoBannerEnabled.publisher
            .removeDuplicates()
            .sink { [weak self] in
                self?.promoBannerEnabled = $0
            }
            .store(in: &cancellables)

        FeatureFlags.default.$newArrivalBadgeEnabled.publisher
            .removeDuplicates()
            .sink { [weak self] in
                self?.newArrivalBadgeEnabled = $0
            }
            .store(in: &cancellables)

        FeatureFlags.default.$wishlistButtonEnabled.publisher
            .removeDuplicates()
            .sink { [weak self] in
                self?.wishlistButtonEnabled = $0
            }
            .store(in: &cancellables)
        
        FeatureFlags.default.$starRatingsEnabled.publisher
            .removeDuplicates()
            .sink { [weak self] in
                self?.starRatingsEnabled = $0
            }
            .store(in: &cancellables)

        FeatureFlags.default.$checkoutType.publisher
            .removeDuplicates()
            .sink { [weak self] in
                self?.checkoutType = $0
            }
            .store(in: &cancellables)
    }
}
