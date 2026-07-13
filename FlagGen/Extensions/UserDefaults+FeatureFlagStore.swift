//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

extension UserDefaults: FeatureFlagStore {
    public func reset(key: String) {
        set(nil, forKey: key)
    }

    public func get<T: RawRepresentable>(key: String) -> T? {
        guard
            let obj = object(forKey: key) as? T.RawValue,
            let val = T.init(rawValue: obj)
        else { return nil }
        return val
    }

    public func set<T: RawRepresentable>(value: T, for key: String) {
        set(value.rawValue, forKey: key)
    }
}

extension UserDefaults: @unchecked @retroactive Sendable {}
extension UserDefaults: ObservableFlagStore {
    func observe<T: RawRepresentable>(key: String, change: @escaping (T?) -> Void) -> NSObject {
        return UserDefaultsObserver(key: key, userDefaults: self) { new in
            change(UserDefaultsObserver.convert(new))
        }
    }
}
