//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

/// Pushes to a separate Settings screen (its own `.plist` file), backed by another
/// `FeatureFlags`-shaped value, instead of adding rows to the current screen.
///
/// ```swift
/// @FeatureFlagChildPane("Advanced Settings")
/// var advancedSettings = AdvancedSettings.default
/// ```
///
/// No further registration is needed — the generator discovers child panes by walking the
/// root `FeatureFlags` struct for `@FeatureFlagChildPane` properties directly.
@propertyWrapper
public struct FeatureFlagChildPane<T>: PListElementProviding, PListSubFileProviding {
    public var wrappedValue: T

    let title: String
    public let filename: String

    /// - Parameters:
    ///   - title: Displayed on the row that pushes to the child pane.
    ///   - filename: The generated `.plist`'s filename (without extension). Defaults to the
    ///     wrapped flags type's name, e.g. `AdvancedSettings`.
    public init(wrappedValue: T, _ title: String, filename: String? = nil) {
        self.wrappedValue = wrappedValue
        self.title = title
        self.filename = filename ?? String(describing: T.self)
    }

    var pListElements: [PListElement] {
        [PListChildPane(title: title, file: filename)]
    }

    var subFileFeatureFlags: Any {
        wrappedValue
    }
}
