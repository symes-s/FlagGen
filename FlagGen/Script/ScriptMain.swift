//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

@main
enum ScriptMain {
    static func main() throws {
        let args = CommandLine.arguments
        guard args.count == 2 else {
            print("Please provide a filepath to output the generated JSON file")
            return
        }
        if args[1] == "--help" {
            print("Generates a JSON file based on the contents of FeatureFlags.swift at the supplied filepath.\nThis is intended to be converted to a plist file with plutil.\ni.e.: `plutil -convert xml1 ${OUTPUT_JSON} -o ${PLIST_OUTPUT}`")
            return
        }

        let plistUrl = URL(fileURLWithPath: args[1])
        let rootFeatureFlags = FeatureFlags.default

        try PListGenerator().generateFeaturesPlistJson(filepath: plistUrl, from: rootFeatureFlags, asPreferenceSpecifier: false)

        let featureFlagRoot = plistUrl.deletingLastPathComponent()
        let enumGenerator = FeatureFlagsEnumGenerator(directoryURL: featureFlagRoot)
        enumGenerator.buildEnum(from: rootFeatureFlags)

        let childPanes = Mirror(reflecting: rootFeatureFlags).children.compactMap { $1 as? PListSubFileProviding }
        for childPane in childPanes {
            let subFileURL = featureFlagRoot.appendingPathComponent(childPane.filename + ".json")
            try PListGenerator().generateFeaturesPlistJson(filepath: subFileURL, from: childPane.subFileFeatureFlags, asPreferenceSpecifier: true)
            enumGenerator.buildEnum(from: childPane.subFileFeatureFlags)
        }
        let generatedFolder = "FeatureFlags"
        try enumGenerator.generateEnum(to: generatedFolder)
        // try enumGenerator.generateUserDefaultsExtensions(to: generatedFolder)
    }
}
