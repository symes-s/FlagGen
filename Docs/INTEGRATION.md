# Integrating FlagGen into an Existing Project

This walks through wiring FlagGen into an app that doesn't have it yet. Every path below matches a real file in [`Example/`](../Example) — open it in a second window as you follow along. See the [README](../README.md) first for how flags are defined and used once this is set up.

## 1. Add the FlagGen package

In Xcode: **File > Add Package Dependencies…**
- If you've cloned this repo locally: click **Add Local…** and select the `flag-gen` folder. (This is how `Example/PetsInParadise.xcodeproj` references it — see the `XCLocalSwiftPackageReference` entry in its `project.pbxproj`.)
- If FlagGen is hosted in its own git remote: paste that URL instead.

Add the `FlagGen` product to your app target — the app needs it at runtime for the property wrappers' storage and change-notification code, and your `FeatureFlags` package (next step) needs it to build the generator.

## 2. Create your own `FeatureFlags` package

Mirror `Example/FeatureFlags/`: a small local Swift package, separate from your app target, that depends on FlagGen and declares your flags.

```
YourProject/
  FeatureFlags/
    Package.swift
    Features.plist                 <- generated, step 4
    FeatureFlags/
      FeatureFlags.swift           <- your flags, step 3
      Enums/                       <- custom enum-backed flag types
      Generated/                   <- generator output, do not hand-edit
```

`Package.swift` (see `Example/FeatureFlags/Package.swift`):

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureFlags",
    platforms: [.iOS("17.0")],
    products: [
        .library(name: "FeatureFlags", targets: ["FeatureFlags"]),
    ],
    dependencies: [
        .package(name: "FlagGen", path: "path/to/flag-gen"), // wherever you cloned FlagGen, relative to this file
    ],
    targets: [
        .target(name: "FeatureFlags", dependencies: ["FlagGen"], path: "FeatureFlags"),
    ]
)
```
Add this local package to your Xcode project the same way as step 1 (**Add Local…**, pointing at your new `FeatureFlags` folder), then add the `FeatureFlags` product to your app target.

## 3. Declare your flags

Write `FeatureFlags/FeatureFlags.swift` using the `@FeatureFlagToggle` / `@FeatureFlagEnum` patterns from "Defining Feature Flags" in the [README](../README.md). For a complete reference, see `Example/FeatureFlags/FeatureFlags/FeatureFlags.swift`

## 4. Generate the `.plist`

FlagGen ships a SwiftPM command plugin that does this for you. From your `FeatureFlags` package folder:
```
swift package generate-feature-flags
```
(If that's not recognized, try `swift package plugin generate-feature-flags`. In Xcode, you can also run it via the package's right-click menu / the "Package Plugin" section.)

Run it every time you add, remove, or rename a flag. It:
1. Compiles FlagGen's source together with your `FeatureFlags` target into a throwaway command-line tool (in a scratch directory — nothing is left behind).
2. Runs that tool, which mirrors over your `FeatureFlags` struct and emits `Features.plist` plus `Generated/Enums/FeatureFlagsEnum.swift`.

See `Plugins/GenerateFeatureFlagsPlugin/Plugin.swift` in this repo for the implementation. If you need to target a specific Swift target in a package with more than one, pass `--target <name>`.

**How step 2 actually produces a `.plist` — `Encodable` → JSON → `plutil`:** every property wrapper (`@FeatureFlagToggle`, `@FeatureFlagEnum`, …) exposes a small `Encodable` struct describing itself in Apple's Settings-bundle schema (e.g. a toggle becomes a `PSToggleSwitchSpecifier` dict with `Key`/`Title`/`DefaultValue` — see `PListToggle`, `PListEnum`, etc. in `FlagGen/PListElements/`). `PListGenerator` uses `Mirror` to walk your `FeatureFlags` struct, collects one of these per flag, and serialises the whole array with a plain `JSONEncoder` — that's the compiled tool's job. The plugin then hands that JSON to Apple's own `plutil -convert xml1`, which converts it straight into a real XML property list. Going via JSON means FlagGen never has to hand-write a plist serialiser — `Encodable` + `JSONEncoder` do the structuring, and `plutil` guarantees the final file is a spec-correct plist.

This is a manual step, not a build phase — compiling a fresh Swift executable on every single build would be slow, and flags change far less often than code does. **Commit the generated `Features.plist` and `FeatureFlagsEnum.swift`** — they're checked-in build artifacts, not throwaway output.

## 5. Add a Settings Bundle to your app

If your app doesn't already have one: **File > New > File… > Settings Bundle**, added to your app target. This becomes the base preferences your app ships with — see `Example/PetsInParadise/PetsInParadise/Resources/Settings.bundle/Root.plist`, which is intentionally just an empty `PreferenceSpecifiers` array; your generated flags get merged in at build time in the next step.

Make sure `Settings.bundle` is a **folder reference** (blue folder icon in Xcode's navigator), not a group — otherwise its internal structure won't be preserved when it's copied into your app.

## 6. Embed the generated flags at build time

Copy `Example/PetsInParadise/embed_feature_flags.sh` next to your app target and adjust the paths near the top (`SETTINGS_BUNDLE_PATH`, `FEATURES_FLAGS_ROOT`) to match your project's layout. This script merges your generated `Features.plist` into the Settings Bundle inside the *built* app — and only for Debug builds, so flags never leak into Release/App Store builds.

Then, in Xcode:

1. Select your app target > **Build Phases** > **+** > **New Run Script Phase**.
2. Name it "Embed Feature Flags".
3. Set the script to `"$SRCROOT/path/to/embed_feature_flags.sh"`.
4. **Drag it below "Copy Bundle Resources"** — it needs your Settings.bundle to already be inside the built app before it can merge into it.
5. Uncheck **"Based on dependency analysis"** — this phase has no declared input/output files, so without this, Xcode may decide there's nothing to do and skip it.

(See the `"Embed Feature Flags"` shell script build phase in `Example/PetsInParadise.xcodeproj/project.pbxproj` for the working reference.)

## 7. Turn off User Script Sandboxing

The script above reads and writes paths — your source `Features.plist`, the Settings.bundle inside the *built* app, scratch files in `$TEMP_DIR` — that aren't declared as explicit Input/Output Files for the build phase. Xcode's **User Script Sandboxing** (on by default since Xcode 15) blocks exactly this kind of undeclared file access, and the script will fail.

Fix: select your **project** (or target — either works; `Example/` sets it at the project level so it applies to every target) > **Build Settings** > search **"User Script Sandboxing"** (`ENABLE_USER_SCRIPT_SANDBOXING`) > set it to **No**.

(The alternative is declaring every path the script touches as Input/Output File Lists, which is more correct but more brittle to keep in sync as flags change. `Example/` takes the simpler route.)

## 8. Build, then verify

Build and run on the Simulator (Debug configuration), then open the **Settings app** and scroll down to your app's name — your flags should render as toggles/pickers, exactly like the GIF at the top of the [README](../README.md).

In your app code:

```swift
import FeatureFlags

if FeatureFlags.default.promoBannerEnabled {
    showPromoBanner()
}
```

Flip a flag in the Settings app and relaunch — the new value takes effect, no rebuild needed. If your code observes the flag's publisher (see "Using Feature Flags" in the [README](../README.md)), or reloads flags on `sceneWillEnterForeground()` (see [/Example](../Example/PetsInParadise/PetsInParadise/SceneDelegate.swift#L11)), it can pick up the change live, without even relaunching.
