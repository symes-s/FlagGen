//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

/// Observes a single `UserDefaults` key.
class UserDefaultsObserver: NSObject {
    let key: String
    private var onChange: (Any) -> Void
    private let userDefaults: UserDefaults
    private var lastValue: Any?
    private var token: NSObjectProtocol?

    init(key: String, userDefaults: UserDefaults = .standard, onChange: @escaping (Any) -> Void) {
        self.onChange = onChange
        self.key = key
        self.userDefaults = userDefaults
        self.lastValue = userDefaults.object(forKey: key)
        super.init()
        token = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: userDefaults,
            queue: nil
        ) { [weak self] _ in
            self?.checkForChange()
        }
    }

    private func checkForChange() {
        let newValue = userDefaults.object(forKey: key)
        guard !Self.valuesAreEqual(newValue, lastValue) else {
            return
        }
        lastValue = newValue
        onChange(newValue as Any)
    }

    private static func valuesAreEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return (lhs as? NSObject)?.isEqual(rhs) ?? false
        default:
            return false
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

extension UserDefaultsObserver {
    static func convert<T: RawRepresentable>(_ new: Any) -> T? {
        guard let rawValue = new as? T.RawValue else { return nil }
        return T(rawValue: rawValue)
    }
}
