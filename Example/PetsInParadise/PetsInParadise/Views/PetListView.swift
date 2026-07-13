//
//  FlagGen
//  Created by Scott Symes
//

import SwiftUI

struct PetListView: View {
    @EnvironmentObject private var flags: AppFeatureFlags
    @EnvironmentObject private var cart: CartStore

    var body: some View {
        NavigationStack {
            List {
                if flags.promoBannerEnabled {
                    PromoBannerView()
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }

                ForEach(Pet.sample) { pet in
                    NavigationLink(value: pet) {
                        PetRowView(pet: pet)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Pets In Paradise 🌴")
            .navigationDestination(for: Pet.self) { pet in
                PetDetailView(pet: pet)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CartView()
                    } label: {
                        Label("Cart (\(cart.pets.count))", systemImage: "cart")
                    }
                }
            }
        }
    }
}

private struct PromoBannerView: View {
    var body: some View {
        Text("🎉 Adopt-a-Palooza! 20% off adoption fees this week!")
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange.opacity(0.2))
    }
}

private struct PetRowView: View {
    @EnvironmentObject private var flags: AppFeatureFlags
    let pet: Pet

    var body: some View {
        HStack(spacing: 12) {
            Text(pet.emoji)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pet.name)
                        .font(.headline)
                    if flags.newArrivalBadgeEnabled && pet.isNewArrival {
                        NewArrivalBadge()
                    }
                }
                Text(pet.breed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if flags.starRatingsEnabled {
                    StarRatingView(rating: pet.rating)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(pet.price))")
                    .font(.headline)
                if flags.wishlistButtonEnabled {
                    WishlistButton()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct NewArrivalBadge: View {
    var body: some View {
        Text("NEW")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

#Preview {
    PetListView()
        .environmentObject(AppFeatureFlags.shared)
        .environmentObject(CartStore())
}
