# Adding a Custom Provider (LaunchDarkly, Firebase Remote Config, ...)

FlagGen ships one provider, `LocalProvider` (backed by `UserDefaults`, `ProviderType.developmentLocal`). Most real apps eventually want a second one — a remote config service, so flags can be changed without shipping a build.

## `ProviderType` is open for extension

`ProviderType` is a struct, not an `enum`, specifically so you can add your own provider types without forking FlagGen — the same pattern Foundation uses for `Notification.Name`:

```swift
import FlagGen

extension ProviderType {
    static let launchDarkly = ProviderType(name: "launchDarkly")
    static let firebaseRemoteConfig = ProviderType(name: "firebaseRemoteConfig")
}
```

## Implementing the provider

Conform to `FeatureFlagProvider`: a `type`, and generic `get`/`set`/`reset` over any `RawRepresentable & Sendable` flag type. The pattern for converting a remote SDK's typed response into `T` is the same one `UserDefaults.get<T: RawRepresentable>` already uses internally: try casting the raw value to `T.RawValue`, then `T(rawValue:)`.

### LaunchDarkly

```swift
import FlagGen
import LaunchDarkly

final class LaunchDarklyFeatureFlagProvider: FeatureFlagProvider {
    let type: ProviderType = .launchDarkly

    func get<T: RawRepresentable & Sendable>(key: String) -> T? {
        // LaunchDarkly's SDK is typed per-kind. Try the Bool variation first (covers
        // @FeatureFlagToggle), then fall back to the String variation (covers
        // @FeatureFlagEnum, where T.RawValue is a String).
        if let boolValue = LDClient.get()?.boolVariation(forKey: key, defaultValue: false) as? T.RawValue {
            return T(rawValue: boolValue)
        }
        if let stringValue = LDClient.get()?.stringVariation(forKey: key, defaultValue: "") as? T.RawValue {
            return T(rawValue: stringValue)
        }
        return nil
    }

    func set<T: RawRepresentable & Sendable>(value: T, for key: String) {
        // LaunchDarkly flags are controlled from their dashboard, not written by the app.
        // No-op here — pair this provider with LocalProvider (via keysDict below) if you
        // want a locally writable dev override too.
    }

    func reset(key: String) {
        // No-op — see `set(value:for:)` above.
    }
}
```

### Firebase Remote Config

```swift
import FlagGen
import FirebaseRemoteConfig

final class FirebaseRemoteConfigProvider: FeatureFlagProvider {
    let type: ProviderType = .firebaseRemoteConfig

    func get<T: RawRepresentable & Sendable>(key: String) -> T? {
        let configValue = RemoteConfig.remoteConfig()[key]
        if let boolValue = configValue.boolValue as? T.RawValue {
            return T(rawValue: boolValue)
        }
        if let stringValue = configValue.stringValue as? T.RawValue {
            return T(rawValue: stringValue)
        }
        return nil
    }

    func set<T: RawRepresentable & Sendable>(value: T, for key: String) {
        // Remote Config values are controlled from the Firebase console, not written by
        // the app. No-op, same reasoning as the LaunchDarkly example above.
    }

    func reset(key: String) {
        // No-op — see `set(value:for:)` above.
    }
}
```

Both examples are illustrative — check the current LaunchDarkly / Firebase SDK docs for the exact variation method names and types before using this in a real app.

## Registering it

```swift
FeatureFlagService.default.setProviders([
    LocalProvider(),
    LaunchDarklyFeatureFlagProvider(),
])
```

**Order matters.** `FeatureFlagService.get` returns the first provider's non-nil value, in registration order. Put `LocalProvider` first during development so a local override always wins over the remote value; for a release build you might register only the remote provider, or put it first instead.

## Declaring a flag against multiple providers

`@FeatureFlagToggle` (and the other property wrappers) already support per-provider keys via `keysDict:`, exactly for this case:

```swift
@FeatureFlagToggle(
    defaultValue: false,
    keysDict: [
        .developmentLocal: "new_checkout_enabled",
        .launchDarkly: "new-checkout-flow",
    ]
)
public var newCheckoutEnabled
```

Each provider looks up its own key from this dictionary — they don't need to share the same key string, since naming conventions differ between a local `snake_case` key and a LaunchDarkly `kebab-case` flag key, for example.
