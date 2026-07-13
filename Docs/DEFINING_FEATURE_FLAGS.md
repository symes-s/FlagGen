# Defining Feature Flags

Every flag is a property on your `FeatureFlags` struct (see [`Example/FeatureFlags/FeatureFlags/FeatureFlags.swift`](../Example/FeatureFlags/FeatureFlags/FeatureFlags.swift)), declared with one of the property wrappers below. Once defined, run `swift package generate-feature-flags` (see [Docs/INTEGRATION.md](INTEGRATION.md)) to regenerate `Features.plist`. See the [README](../README.md) for how flags are read back in your app once they're defined.

## `@FeatureFlagToggle` — a `Bool` switch

```swift
@FeatureFlagToggle(defaultValue: true, key: "name_of_key_enabled", title: "Name displayed in Settings App (optional)")
public var exampleToggleEnabled: Bool
```

**The naming convention is that _toggle_ feature flags should end with `_enabled` / `Enabled` as in the example above.**

The title (shown in the Settings app) is optional as it can be synthesised from the key with the following rules:
- Underscores `_` are replaced with spaces ` `
- Instances of "enabled" are removed
- Words will be Capitalised

## `@FeatureFlagEnum` — a picker on a secondary screen

First, an `enum` must be defined in a file in `/FeatureFlags/Enums/`.

The `enum` should be `RawRepresentable`, `public`, and conform to `PListEnumDefining`:

```swift
public enum PetType: String, CaseIterable {
  case cat
  case dog
}
```
The values displayed in the Settings app are defined by `PListEnumDefining` conformance.

```swift
extension PetType: PListEnumDefining {

  public static var pListTitle: String { "Type of pet to use" }

  // Options to select from as displayed on secondary Settings screen
  public var pListElementTitle: String {
    switch self {
    case .cat: return "Haughty Cat"
    case .dog: return "Scruffy Dog"
    }
  }

  // Selected value as displayed on primary Settings screen
  public var pListElementShortTitle: String? {
    switch self {
    case .cat: return "Cat"
    case .dog: return "Dog"
    }
  }
}
```
The `enum` can now be used in the `FeatureFlags.swift` file by adding a `@FeatureFlagEnum` property wrapper:
```swift
@FeatureFlagEnum(defaultValue: .cat, key: "name_of_key")
public var petType: PetType
```

A complete, working version of this pattern is `Example/FeatureFlags/FeatureFlags/Enums/CheckoutType.swift`, used by `@FeatureFlagEnum` in `Example/FeatureFlags/FeatureFlags/FeatureFlags.swift`.

## `@FeatureFlagRadioGroup` — a picker inline on the same screen

Same shape as `@FeatureFlagEnum` — any type conforming to `PListEnumDefining` works with both, since `PListEnumDefining` already includes everything `@FeatureFlagRadioGroup` needs. The difference is purely presentational: `@FeatureFlagEnum` renders as a row that pushes to a secondary picker screen, `@FeatureFlagRadioGroup` renders the options inline as a radio group on the current screen.

```swift
@FeatureFlagRadioGroup(defaultValue: .cat, key: "pet_type_inline", footer: "Choose your favourite")
public var petTypeInline: PetType
```

`footer` (optional) adds explanatory text below the radio group. `sortByTitle` (optional, defaults to `true`) alphabetises the options by their `pListElementTitle`.

## `@FeatureFlagSlider` — a numeric slider

Works with any `Int` or `Double` — no custom type needed, since FlagGen already makes both `RawRepresentable`.

```swift
@FeatureFlagSlider(defaultValue: 5, key: "retry_count", range: 0...10, title: "Retry Count")
public var retryCount: Int
```

`range` is required for the slider to render in Settings (it's what the slider drags between); omit it and the flag still works in code but produces no Settings UI. `title` is optional and falls back to a title synthesised from `key`, the same rules as `@FeatureFlagToggle`.

## `@FeatureFlagTitle` — a read-only info row

Displays a value in Settings without letting the user edit it — useful for diagnostic info the app itself sets (e.g. a detected app version, or the currently-resolved value of a remote-config-backed flag), rather than user-facing configuration.

```swift
@FeatureFlagTitle(defaultValue: "1.0.0", key: "app_version", title: "App Version")
public var appVersion: String
```

## `@FeatureFlagGroup` — a section header

Purely a visual section divider in the Settings screen — it has no associated flag value.

```swift
@FeatureFlagGroup("Checkout", footer: "Controls related to the checkout flow")
var checkoutGroup
```

## `@FeatureFlagChildPane` — a nested settings screen

Pushes to a separate Settings screen (its own `.plist` file) instead of adding rows to the current one — handy once a `FeatureFlags` struct grows too large for a single screen. The child pane's own flags live in a *separate* `FeatureFlags`-shaped struct (its own `@FeatureFlagToggle`s, etc.) — say `AdvancedSettings`:

```swift
// In FeatureFlags.swift:
@FeatureFlagChildPane("Advanced Settings")
var advancedSettings = AdvancedSettings.default
```

That's the whole wiring — no separate registration step needed. The generator discovers child panes by walking the root `FeatureFlags` struct directly for `@FeatureFlagChildPane` properties, the same way it discovers every other flag. The generated filename defaults to the wrapped type's name (`AdvancedSettings.plist` here); pass an explicit `filename:` argument if you want something else.

The generator produces this as a separate `AdvancedSettings.plist` alongside `Features.plist`, and `embed_feature_flags.sh` copies it into the Settings Bundle too — see step 6 in [Docs/INTEGRATION.md](INTEGRATION.md).
