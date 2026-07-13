#! /bin/bash

# script is called by build phase

set -xeu
set -o pipefail

echo "Configuration: ${CONFIGURATION}"

SETTINGS_BUNDLE_PATH="${SRCROOT}/PetsInParadise/PetsInParadise/Resources/Settings.bundle"
SETTINGS_PLIST="${SETTINGS_BUNDLE_PATH}/Root.plist"

FEATURES_FLAGS_ROOT="${SRCROOT}/FeatureFlags"
FEATURES_PLIST="${FEATURES_FLAGS_ROOT}/Features.plist"
SETTINGSBUNDLEPATH="${CODESIGNING_FOLDER_PATH}/Settings.bundle"
SETTINGSBUNDLEROOTPLIST="${SETTINGSBUNDLEPATH}/Root.plist"
TEMP_PLIST="${TEMP_DIR}/Temp.plist"

# Remove temp plist from previous builds, should it exist
rm -rf "$TEMP_PLIST"

# Copy existing settings to temp plist
/usr/libexec/PlistBuddy -c "Merge '$SETTINGS_PLIST'" "$TEMP_PLIST"

if [[ "$CONFIGURATION" == *"Debug"* ]]; then
    # Copy feature flags to temp plist
    /usr/libexec/PlistBuddy -c "Merge '$FEATURES_PLIST' 'PreferenceSpecifiers'" "$TEMP_PLIST"

    for filepath in ${FEATURES_FLAGS_ROOT}/*.plist; do
        # Skip base Features.plist file
        [[ "$filepath" == ${FEATURES_PLIST} ]] && continue
        filename="${filepath##*/}"
        cp "$filepath" "$SETTINGSBUNDLEPATH/$filename"
    done
fi

# Copy final temp plist to final app bundle
cp "$TEMP_PLIST" "$SETTINGSBUNDLEROOTPLIST"
