//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

final class CartStore: ObservableObject {
    @Published var pets: [Pet] = []

    var total: Double {
        pets.reduce(0) { $0 + $1.price }
    }

    func add(_ pet: Pet) {
        pets.append(pet)
    }

    func remove(_ pet: Pet) {
        pets.removeAll { $0.id == pet.id }
    }

    func clear() {
        pets.removeAll()
    }
}
