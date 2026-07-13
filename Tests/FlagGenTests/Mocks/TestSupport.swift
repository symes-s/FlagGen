//
//  FlagGen
//  Created by Scott Symes
//

import Foundation
@testable import FlagGen

/// String-backed custom `RawRepresentable` enum used across tests to exercise the
/// conversion path that plain identity types (`Bool`/`Int`/`Double`/`String`) can't:
/// `UserDefaults` always hands back the *stored* raw value, not `Self`.
enum TestPetType: String, CaseIterable, PListEnumDefining, Encodable {
    case cat
    case dog

    static var pListTitle: String { "Pet Type" }

    var pListElementTitle: String {
        switch self {
        case .cat: return "Haughty Cat"
        case .dog: return "Scruffy Dog"
        }
    }

    var pListElementShortTitle: String? {
        switch self {
        case .cat: return "Cat"
        case .dog: return "Dog"
        }
    }
}

/// Int-backed custom `RawRepresentable` enum, for coverage distinct from `TestPetType`.
enum TestPriority: Int, CaseIterable, PListEnumDefining {
    case low = 1
    case medium = 5
    case high = 10

    static var pListTitle: String { "Priority" }

    var pListElementTitle: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var pListElementShortTitle: String? { nil }
}
