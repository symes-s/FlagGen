//
//  FlagGen
//  Created by Scott Symes
//

import SwiftUI

struct PetDetailView: View {
    @EnvironmentObject private var flags: AppFeatureFlags
    @EnvironmentObject private var cart: CartStore
    @State private var didAddToCart = false

    let pet: Pet

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(pet.emoji)
                        .font(.system(size: 80))
                    Spacer()
                    if flags.wishlistButtonEnabled {
                        WishlistButton()
                    }
                }

                if flags.newArrivalBadgeEnabled && pet.isNewArrival {
                    NewArrivalBadge()
                }

                Text(pet.name)
                    .font(.largeTitle.bold())
                Text(pet.breed)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                if flags.starRatingsEnabled {
                    StarRatingView(rating: pet.rating)
                }

                Text(pet.description)
                    .font(.body)

                Text("$\(Int(pet.price))")
                    .font(.title2.bold())

                Button {
                    cart.add(pet)
                    didAddToCart = true
                } label: {
                    Label(didAddToCart ? "Added to Cart" : "Add to Cart", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(didAddToCart)
            }
            .padding()
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PetDetailView(pet: Pet.sample[0])
    }
    .environmentObject(AppFeatureFlags.shared)
    .environmentObject(CartStore())
}
