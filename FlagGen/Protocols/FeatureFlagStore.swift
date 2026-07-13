//
//  FlagGen
//  Created by Scott Symes
//

import Combine
import Foundation

public protocol FeatureFlagStore {
    func get<T: RawRepresentable>(key: String) -> T?
    func set<T: RawRepresentable>(value: T, for key: String)
    func reset(key: String)
}

protocol ObservableFlagStore: FeatureFlagStore, Sendable {
    func observe<T: RawRepresentable>(key: String, change: @escaping (T?) -> Void) -> NSObject
}
