//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

struct Pet: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let breed: String
    let emoji: String
    let price: Double
    let rating: Int
    let isNewArrival: Bool
    let description: String
}

extension Pet {
    static let sample: [Pet] = [
        Pet(
            name: "Sir Waggington",
            breed: "Golden Retriever",
            emoji: "🐶",
            price: 450,
            rating: 5,
            isNewArrival: true,
            description: "Sir Waggington greets every visitor with a full-body wag and a tennis ball he insists you throw. Comes with a lifetime supply of good vibes."
        ),
        Pet(
            name: "Luna",
            breed: "Tabby Cat",
            emoji: "🐱",
            price: 220,
            rating: 4,
            isNewArrival: false,
            description: "Luna runs the shop from her favourite sunny windowsill. She'll allow you to pet her, on her schedule, not yours."
        ),
        Pet(
            name: "Captain Feathers",
            breed: "Macaw",
            emoji: "🦜",
            price: 680,
            rating: 5,
            isNewArrival: true,
            description: "Captain Feathers knows three sea shanties and one very rude word he won't say in front of children. Mostly."
        ),
        Pet(
            name: "Bubbles",
            breed: "Goldfish",
            emoji: "🐠",
            price: 15,
            rating: 3,
            isNewArrival: false,
            description: "Bubbles has the memory of, well, a goldfish, which means every lap of the tank is a brand new adventure for him."
        ),
        Pet(
            name: "Shelly",
            breed: "Box Turtle",
            emoji: "🐢",
            price: 90,
            rating: 4,
            isNewArrival: false,
            description: "Shelly is in no hurry to be adopted, or to do anything else. A very calming presence for the shop."
        ),
        Pet(
            name: "Clover",
            breed: "Holland Lop Rabbit",
            emoji: "🐰",
            price: 120,
            rating: 5,
            isNewArrival: true,
            description: "Clover has floppy ears, a twitchy nose, and a talent for escaping enclosures that should not be possible."
        )
    ]
}
