//
//  FlagGen
//  Created by Scott Symes
//

#if canImport(FlagGen)
import FlagGen
#endif
import Foundation

public enum CheckoutType: String, CaseIterable, Identifiable {
    case standard
    case express
    case vip

    public var id: String { rawValue }
}

extension CheckoutType: PListMultiValueDefining {
    public static var pListTitle: String { "Checkout Type" }

    public var pListElementTitle: String {
        switch self {
        case .standard: "🎰 Standard"
        case .express:  "⚡ Express"
        case .vip:      "💎 VIP"
        }
    }
    
    public var pListElementShortTitle: String? {
        switch self {
        case .standard: "🎰"
        case .express:  "⚡"
        case .vip:      "💎"
        }
    }
}
