//
//  FlagGen
//  Created by Scott Symes
//

import FeatureFlags
import SwiftUI

struct CartView: View {
    @EnvironmentObject private var flags: AppFeatureFlags
    @EnvironmentObject private var cart: CartStore
    @State private var showConfirmation = false

    var body: some View {
        VStack {
            if cart.pets.isEmpty {
                ContentUnavailableView(
                    "Your cart is empty",
                    systemImage: "cart",
                    description: Text("Add a new best friend from the pet list")
                )
            } else {
                List {
                    ForEach(cart.pets) { pet in
                        HStack {
                            Text(pet.emoji)
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text(pet.name).font(.headline)
                                Text("$\(Int(pet.price))").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.map { cart.pets[$0] }.forEach(cart.remove)
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("$\(Int(cart.total))")
                            .font(.headline)
                    }

                    checkoutButton
                }
                .padding()
            }
        }
        .navigationTitle("Your Cart")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Adoption Confirmed! 🎉", isPresented: $showConfirmation) {
            Button("OK") { cart.clear() }
        } message: {
            Text("Your new friends will be ready for pickup shortly.")
        }
    }

    @ViewBuilder
    private var checkoutButton: some View {
        switch flags.checkoutType {
        case .standard:
            Button {
                showConfirmation = true
            } label: {
                Text("Checkout")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

        case .express:
            Button {
                showConfirmation = true
            } label: {
                Label("Express Checkout", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

        case .vip:
            VStack(spacing: 8) {
                Text("✨ Includes free grooming & priority delivery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    showConfirmation = true
                } label: {
                    Label("VIP Checkout", systemImage: "crown.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CartView()
    }
    .environmentObject(AppFeatureFlags.shared)
    .environmentObject(CartStore())
}
