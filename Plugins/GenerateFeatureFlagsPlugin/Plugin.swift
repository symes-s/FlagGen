//
//  FlagGen
//  Created by Scott Symes
//

import Foundation
import PackagePlugin

/// Compiles FlagGen's source together with a consumer's `FeatureFlags` target and runs the
/// result to produce `Features.plist` and `Generated/Enums/FeatureFlagsEnum.swift`.
///
/// Run from your `FeatureFlags` package with:
///   swift package generate-feature-flags
/// or via Xcode's "FeatureFlags > GenerateFeatureFlags" plugin menu.
@main
struct GenerateFeatureFlagsPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        let requestedTargetName = extractor.extractOption(named: "target").first

        guard let flagGenDependency = context.package.dependencies.first(where: { $0.package.displayName == "FlagGen" }) else {
            throw GenerationError.flagGenDependencyNotFound
        }
        let flagGenSourceDirectory = flagGenDependency.package.directory.appending(subpath: "FlagGen")

        let candidateTargets = context.package.targets.compactMap { $0 as? SwiftSourceModuleTarget }
        guard let target = resolveTarget(named: requestedTargetName, in: candidateTargets) else {
            throw GenerationError.noTargetFound(requestedTargetName)
        }

        let flagGenSources = try swiftFilePaths(under: flagGenSourceDirectory)
        let targetSources = target.sourceFiles.map(\.path).filter { $0.string.hasSuffix(".swift") }

        guard !targetSources.isEmpty else {
            throw GenerationError.emptyTarget(target.name)
        }

        print("Compiling FlagGen + \(target.name) (\(flagGenSources.count + targetSources.count) files)…")

        let compiledToolPath = context.pluginWorkDirectory.appending(subpath: "GeneratedFlagGenTool")
        try run(
            "/usr/bin/xcrun",
            arguments: ["--sdk", "macosx", "swiftc", "-parse-as-library"]
                + (flagGenSources + targetSources).map(\.string)
                + ["-o", compiledToolPath.string]
        )

        // ScriptMain derives the output directory from this path's parent, so it must live
        // directly in the package root for `FeatureFlagsEnum.swift` to land in the right place.
        let intermediateJSON = context.package.directory.appending(subpath: "GeneratedFeatures.json")
        try run(compiledToolPath.string, arguments: [intermediateJSON.string])

        let featuresPlist = context.package.directory.appending(subpath: "Features.plist")
        try convertToPlist(json: intermediateJSON, plist: featuresPlist)
        try FileManager.default.removeItem(atPath: intermediateJSON.string)

        // Any @FeatureFlagChildPane sub-panes get written as sibling <name>.json files —
        // convert and clean those up too.
        let remainingJSONFiles = try FileManager.default.contentsOfDirectory(atPath: context.package.directory.string)
            .filter { $0.hasSuffix(".json") }
        for jsonFilename in remainingJSONFiles {
            let jsonPath = context.package.directory.appending(subpath: jsonFilename)
            let plistPath = context.package.directory.appending(subpath: String(jsonFilename.dropLast(5)) + ".plist")
            try convertToPlist(json: jsonPath, plist: plistPath)
            try FileManager.default.removeItem(atPath: jsonPath.string)
        }

        print("Generated \(featuresPlist.string)")
        print("Generated \(target.directory.appending(subpath: "Generated/Enums/FeatureFlagsEnum.swift").string)")
    }

    private func resolveTarget(named name: String?, in targets: [SwiftSourceModuleTarget]) -> SwiftSourceModuleTarget? {
        if let name {
            return targets.first(where: { $0.name == name })
        }
        return targets.first
    }

    private func swiftFilePaths(under directory: Path) throws -> [Path] {
        guard let enumerator = FileManager.default.enumerator(atPath: directory.string) else { return [] }
        var results: [Path] = []
        for case let relativePath as String in enumerator where relativePath.hasSuffix(".swift") {
            results.append(directory.appending(subpath: relativePath))
        }
        return results
    }

    private func convertToPlist(json: Path, plist: Path) throws {
        try run("/usr/bin/plutil", arguments: ["-convert", "xml1", json.string, "-o", plist.string])
    }

    private func run(_ executablePath: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw GenerationError.processFailed(executablePath, process.terminationStatus)
        }
    }
}

enum GenerationError: Error, CustomStringConvertible {
    case flagGenDependencyNotFound
    case noTargetFound(String?)
    case emptyTarget(String)
    case processFailed(String, Int32)

    var description: String {
        switch self {
        case .flagGenDependencyNotFound:
            return "Could not find a 'FlagGen' package dependency. Add FlagGen as a dependency of this package first."
        case .noTargetFound(let name):
            if let name {
                return "No target named '\(name)' in this package."
            }
            return "This package has no Swift targets to generate flags for."
        case .emptyTarget(let name):
            return "Target '\(name)' has no Swift source files."
        case .processFailed(let tool, let status):
            return "\(tool) exited with status \(status)."
        }
    }
}
