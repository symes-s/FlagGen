//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

final class FeatureFlagsEnumGenerator {
    private var metadata: [FlagMetadata] = []
    private let directoryURL: URL
    private lazy var fileManager: FileManager = FileManager.default

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    private struct FlagMetadata {
        let name: String
        let localKey: String?
        let keys: [ProviderKey]
        let valueType: String
        let defaultValue: String?
        let rawType: String?
        let rawDefault: String?

        var providerNames: [String] {
            keys.map { $0.provider.name }.sorted()
        }

        var providersKey: String {
            providerNames.joined(separator: ".")
        }

        func providerKey(stripping provider: ProviderType) -> String {
            return providerNames.filter { $0 != provider.name }.joined(separator: ".")
        }

        var providerEnums: [String] {
            providerNames.map { ".\($0)" }
        }

        var providersEnumArray: String {
            "[\(providerEnums.joined(separator: ", "))]"
        }

        var isObjcType: Bool {
            switch valueType {
            case "Int", "Bool", "String", "Double":
                true
            default:
                false
            }
        }
    }

    func buildEnum(from object: Any) {
        metadata += getFlagMetadata(from: object)
    }

    // output: FeatureFlags/Enums/
    func generateEnum(to outputRootPath: String, subPaths: String = "Generated/Enums", filename: String = "FeatureFlagsEnum.swift") throws {
        // swiftlint:disable:next no_direct_standard_out_logs
        let newDirectoryURL = directoryURL
            .appendingPathComponent(outputRootPath, isDirectory: true)
            .appendingPathComponent(subPaths, isDirectory: true)

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: newDirectoryURL.path, isDirectory: &isDirectory)
        if !exists || !isDirectory.boolValue {
            try fileManager.createDirectory(at: newDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        let filename = filename.hasSuffix(".swift") ? filename : "\(filename).swift"
        let fileURL = newDirectoryURL
            .appendingPathComponent(filename)

        print("Updating Feature Flag Toggle Enum")

        print("\t\tGot \(metadata.count) FeatureFlags (toggle & enum types)")

        let enumLines: String = enumsFile(metadata)

        var numLines = 0
        (enumLines as NSString).enumerateLines { _, _ in numLines += 1 }

        try Data(enumLines.utf8).write(to: fileURL)

        print("\t\tGenerated a total of \(numLines) lines")
        try Data(enumLines.utf8).write(to: fileURL)
        print("\t\tSuccessfully written Feature Flag Toggle Enum file")
    }

    // output: FeatureFlags/Extensions
    func generateUserDefaultsExtensions(to outputRootPath: String, subPaths: String = "Generated/Extensions", filename: String = "UserDefaults+Publishers.swift") throws {
        // swiftlint:disable:next no_direct_standard_out_logs
        let fileContents = userDefaultsFile(metadata)
        let newDirectoryURL = directoryURL
            .appendingPathComponent(outputRootPath, isDirectory: true)
            .appendingPathComponent(subPaths, isDirectory: true)

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: newDirectoryURL.path, isDirectory: &isDirectory)
        if !exists || !isDirectory.boolValue {
            try fileManager.createDirectory(at: newDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        let fileURL = newDirectoryURL.appendingPathComponent(filename) // , conformingTo: .swiftSource)

        print("\t\tGenerated UserDefaults Extension")
        try Data(fileContents.utf8).write(to: fileURL)
        print("\t\tSuccessfully written UserDefaults Extension")
    }

    private func getFlagMetadata(from object: Any) -> [FlagMetadata] {
        // TODO: Include enum types too and capture the value Type
        return Mirror(reflecting: object).children.compactMap { child -> FlagMetadata? in
            guard
                let keys = (child.value as? FeatureFlagKeysProviding)?.keys as? [ProviderKey],
                let valueType = (child.value as? FeatureFlagKeysProviding)?.defaultType,
                let label = child.label else {
                return nil
            }
            let name = String(label.dropFirst()).replacingOccurrences(of: "Enabled", with: "") // first char is always "_"
            let localKey = keys.first(where: { $0.provider == .developmentLocal })?.key
            if let valueProviding = (child.value as? (any FeatureFlagDefaultValueProviding)) {
                return FlagMetadata(
                    name: name,
                    localKey: localKey,
                    keys: keys,
                    valueType: valueType,
                    defaultValue: valueProviding.defaultValueString,
                    rawType: valueProviding.rawValueType,
                    rawDefault: valueProviding.defaultRawValueString
                )
            } else {
                return FlagMetadata(name: name, localKey: localKey, keys: keys, valueType: valueType, defaultValue: nil, rawType: nil, rawDefault: nil)
            }
        }
    }
}

// MARK: - Enums File
extension FeatureFlagsEnumGenerator {
    private var className: String { "FeatureFlagsEnum" }

    private func enumsFile(_ metadata: [FlagMetadata]) -> String {
        let localEnumLines = mainEnum(metadata, extn: nil)

        let extensionStart = extensionStart(metadata, extn: nil)

        let otherProvidersExtension = otherProvidersExtension(metadata)

        let keysExten = keysExtension(metadata)

        let typeExten = typeExtension(metadata, extn: nil)

        return localEnumLines + extensionStart + otherProvidersExtension + keysExten + "\n}" + typeExten + "\n//swiftlint:enable all"
    }

    /**
     Sample code:
     ```
     public enum FeatureFlagEnum: String, CaseIterable {
     case certificateLifecycle = "certificate_lifecycle"
     case covid19PackdownPhase2 = "covid19_packdown_phase_2_enabled"
     case vaxCertificates = "certificate-feature-enabled"
     case raTestVersion2 = "rat_version_2_enabled"
     …
     …
     }
     ```
     */
    private func mainEnum(_ metadata: [FlagMetadata], extn: String?) -> String {
        var noLocalKeyCount = 0
        var noLocalKey: String {
            noLocalKeyCount += 1
            return "no-local-key-\(noLocalKeyCount)"
        }
        let localCaseLines = metadata.map { String(format: "    case %@ = \"%@\"", $0.name, $0.localKey ?? noLocalKey) }.joined(separator: "\n")
        let localStartLines = """
// swiftlint:disable all
// Generated from the set of `FeatureFlagToggle`s and `FeatureFlagEnum`s in `FeatureFlags.swift`
// by `FlagGen`
//
// This file is required for UnitTest mocks
//
// - Do Not Edit -

#if canImport(FlagGen)
import FlagGen
#endif
import Foundation

public enum \(className)\(extn ?? ""): String, CaseIterable {\n
"""

        return localStartLines + localCaseLines + "\n}"
    }

    /**
     Sample code:
     ```
     extension FeatureFlagEnum {

     public var localKey: String {
     self.rawValue
     }

     public var providerTypes: [ProviderType] {
     switch self {
     case .vaxCertificates:                     return [.developmentLocal, .statusConfig]
     case .vaxBoosterNotificationUseVaxStatus:  return [.developmentLocal, .statusConfig]
     case .createAccount:                       return [.developmentLocal, .statusConfig]
     case .raTestCheckin:                       return [.developmentLocal, .statusConfig]
     default:                                   return [.developmentLocal]
     }
     }
     ```
     */
    private func extensionStart(_ metadata: [FlagMetadata], extn: String?) -> String {
        let extensionStart = """
\n\nextension \(className)\(extn ?? "") {
    public var localKey: String {
        self.rawValue
    }

    public var providerTypes: [ProviderType] {
        switch self {

"""
        let grouped = Dictionary(grouping: metadata) { $0.providersKey }.filter { $0.key != ProviderType.developmentLocal.name }
        let moreThanOneType = grouped.values.flatMap { $0 }
        let casesMaxLength = moreThanOneType.reduce(into: 0, { $0 = $1.name.count > $0 ? $1.name.count : $0 })

        let extensionVarCases = moreThanOneType.map { String(format: "      case .%@: %@ %@", $0.name, padding($0.name, maxLength: casesMaxLength), $0.providersEnumArray) }.joined(separator: "\n")

        return extensionStart + extensionVarCases + String(format: "        default:%@ [.developmentLocal]\n        }\n    }", padding("", maxLength: casesMaxLength))
    }

    /**
     Sample code:
     ```
     public var statusConfigKey: String? {
     switch self {
     case .vaxCertificates:                     return "certificate-feature-enabled"
     case .vaxBoosterNotificationUseVaxStatus:  return "vax-booster-feature-enabled"
     case .createAccount:                       return "create-account-enabled"
     case .raTestCheckin:                       return "rat-feature-enabled"
     default:                                   return nil
     }
     }
     ```
     */
    private func otherProvidersExtension(_ metadata: [FlagMetadata]) -> String {
        let grouped = group(metadata, without: .developmentLocal)

        return grouped.map { group -> String in
            let extensionRemotesStart = """
\n\n    public var \(groupEnumName(group.key)): String? {
    switch self {
"""
            let casesMaxLength = group.value.reduce(into: 0, { $0 = $1.name.count > $0 ? $1.name.count : $0 })
            let extensionRemoteCases = group.value.map { String(format: "          case .%@: %@ \"%@\"", $0.name, padding($0.name, maxLength: casesMaxLength), $0.keys.first!.key) }.joined(separator: "\n")

            return extensionRemotesStart + extensionRemoteCases + String(format: "\n          default:%@ nil\n    }\n  }", padding("", maxLength: casesMaxLength))
        }.joined(separator: "\n")
    }

    /**
     Sample code:
     ```
     public var keys: [ProviderKey] {
         var keys = [ProviderKey(provider: .developmentLocal, key: self.localKey)]
         if let statusConfigKey = statusConfigKey {
             keys.append(ProviderKey(provider: .statusConfig, key: statusConfigKey))
         }
         return keys
     }
     ```
     */
    private func keysExtension(_ metadata: [FlagMetadata]) -> String {
        let grouped = group(metadata, without: .developmentLocal)

        let keysStart = """
\n\n    public var keys: [ProviderKey] {
      var keys = [ProviderKey(provider: .developmentLocal, key: self.localKey)]
"""

        let keysMiddle = grouped.compactMap { group in
            return group.value.first?.providerNames.filter({ $0 != ProviderType.developmentLocal.name }).compactMap { (provider: String?) -> String? in
                guard let provider = provider else {
                    return nil
                }
                let variableName = groupEnumName(group.key)
                return "\n    if let \(variableName) = \(variableName) {\n      keys.append(ProviderKey(provider: .\(provider), key: \(variableName)))\n    }"
            }.joined(separator: "\n")
        }

        let keysEnd = """
\n      return keys
    }
"""
        if keysMiddle.count > 0 {
            return keysStart + keysMiddle.joined(separator: "\n") + keysEnd
        } else {
            return """
\n\n    public var keys: [ProviderKey] {
        [ProviderKey(provider: .developmentLocal, key: self.localKey)]
    }
"""
        }
    }

    /// Provide an extra extension so that Type can be determined (useful for including non-Bool types)
    private func typeExtension(_ metadata: [FlagMetadata], extn: String?) -> String {
        let extensionStart = """
\n\nextension \(className)\(extn ?? "") {
    public var valueType: Any.Type {
        switch self {

"""
        let otherTypes = Dictionary(grouping: metadata.map { ($0.name, $0.valueType) }, by: { $0.1 }).filter { $0.key != "\(Bool.self)" }.flatMap { $0.value }.sorted(by: { $0.0 < $1.0 })
        let casesMaxLength = otherTypes.reduce(into: 0, { $0 = $1.0.count > $0 ? $1.0.count : $0 })
        let otherTypeLines = otherTypes.map { "        case .\($0.0): \(padding($0.0, maxLength: casesMaxLength))\($0.1).self" }.joined(separator: "\n")
        let otherTypesEnd = "\n        default:\(padding("", maxLength: casesMaxLength))Bool.self\n        }\n    }"

        return extensionStart + otherTypeLines + otherTypesEnd + "\n}"
    }

    // MARK: Helpers
    private func padding(_ name: String, maxLength: Int) -> String {
        String(repeating: " ", count: max(maxLength - name.count, 0))
    }

    private func groupEnumName(_ groupKey: String) -> String {
        groupKey.replacingOccurrences(of: "developmentLocal", with: "").replacingOccurrences(of: ".", with: "") + "Key"
    }

    private func group(_ metadata: [FlagMetadata], without providerType: ProviderType) -> [String: [FlagMetadata]] {
        let grouped = Dictionary(grouping: metadata) { $0.providersKey }.filter { $0.key != providerType.name }
        let metadataWithoutProviderType: [FlagMetadata] = grouped.flatMap { $0.value }.sorted { $0.name < $1.name }
        return Dictionary(grouping: metadataWithoutProviderType) { $0.providerKey(stripping: providerType) }
    }
}

// MARK: - User Defaults File
extension FeatureFlagsEnumGenerator {
    private func userDefaultsFile(_ metadata: [FlagMetadata]) -> String {
        let userDefaultsStart = """
        // swiftlint:disable all
        // Generated from the set of `FeatureFlagToggle`s and `FeatureFlagEnum`s in `FeatureFlags.swift`
        // by `FlagGen`
        //
        // - Do Not Edit -
        
        import Combine
        #if canImport(FlagGen)
        import FlagGen
        #endif
        import Foundation
        
        """
        let userDefaultsExtension = userDefaultsExtension(metadata)
        let userDefaultsPublishers = userDefaultsPublisherExtension(metadata)

        return userDefaultsStart + userDefaultsPublishers + userDefaultsExtension + "\n// swiftlint:enable all"
    }

    /**
     extension UserDefaults {
         @objc dynamic var noInternetBanner: Bool {
             get { (object(forKey: FeatureFlagsEnum.noInternetBanner.rawValue) as? Bool) ?? true }
            set { set(newValue, forKey: FeatureFlagsEnum.noInternetBanner.rawValue) }
         }

         @objc dynamic var mockStepCountData: Bool {
             get { (object(forKey: FeatureFlagsEnum.mockStepCountData.rawValue) as? Bool) ?? true }
             set { set(newValue, forKey: FeatureFlagsEnum.mockStepCountData.rawValue) }
         }
     }
     */
    private func userDefaultsExtension(_ metadata: [FlagMetadata]) -> String {
        let extensionStart = "\n\n// MARK: - Internal KVO Properties\nextension UserDefaults {\n"
        var lines: [String] = []
        for data in metadata {
            let new: String
            if let defaultValue = data.defaultValue {
                let defaultRepresentation = data.valueType == "String" ? "\"\(defaultValue)\"" : defaultValue
                if data.isObjcType {
                    new = """
                @objc dynamic var \(data.name): \(data.valueType) {
                    get { (object(forKey: FeatureFlagsEnum.\(data.name).rawValue) as? \(data.valueType)) ?? \(defaultRepresentation) }
                    set { set(newValue, forKey: FeatureFlagsEnum.\(data.name).rawValue) }
                }
            """
                } else if let rawType = data.rawType, let rawDefault = data.rawDefault {
                    let rawdefaultRepresentation = rawType == "String" ? "\"\(rawDefault)\"" : rawDefault
                    new = """
                @objc dynamic var \(data.name)Value: \(rawType) {
                    get { (object(forKey: FeatureFlagsEnum.\(data.name).rawValue) as? \(rawType)) ?? \(rawdefaultRepresentation) }
                    set { set(newValue, forKey: FeatureFlagsEnum.\(data.name).rawValue) }
                }
            """
                } else {
                    new = """
                var \(data.name): \(data.valueType) {
                    get { (object(forKey: FeatureFlagsEnum.\(data.name).rawValue) as? \(data.valueType)) ?? \(defaultRepresentation) }
                    set { set(newValue, forKey: FeatureFlagsEnum.\(data.name).rawValue) }
                }
            """
                }
            } else {
                new = """
                \(data.isObjcType ? "@objc dynamic " : "")var \(data.name): \(data.valueType)? {
                    get { object(forKey: FeatureFlagsEnum.\(data.name).rawValue) as? \(data.valueType) }
                    set { set(newValue, forKey: FeatureFlagsEnum.\(data.name).rawValue) }
                }
            """
            }
            lines.append(new)
        }

        return extensionStart + lines.joined(separator: "\n\n") + "\n}"
    }

    /// public extension UserDefaults {
    ///     var noInternetBannerPublisher: AnyPublisher<Bool, Never> {
    ///         publisher(for: \.noInternetBanner).eraseToAnyPublisher()
    ///     }
    /// }
    private func userDefaultsPublisherExtension(_ metadata: [FlagMetadata]) -> String {
        let extensionStart = "\n// MARK: - Public Publishers\npublic extension UserDefaults {\n"
        var lines: [String] = []
        for data in metadata {
            let new: String
            if data.isObjcType {
                new = """
                var \(data.name)Publisher: AnyPublisher<\(data.valueType), Never> {
                    publisher(for: \\.\(data.name)).eraseToAnyPublisher()
                }
            """
            } else if var defaultValue = data.defaultValue {
                if let _ = Int(defaultValue) {
                    //
                } else if let _ = Double(defaultValue) {
                    //
                } else {
                    defaultValue = ".\(defaultValue)"
                }
                new = """
                var \(data.name)Publisher: AnyPublisher<\(data.valueType), Never> {
                    publisher(for: \\.\(data.name)Value)
                        .map { rawValue in
                            guard let result = \(data.valueType)(rawValue: rawValue) else {
                                return \(defaultValue)
                            }
                            return result
                        }
                        .eraseToAnyPublisher()
                }
            """
            } else {
                continue
            }
            lines.append(new)
        }

        return extensionStart + lines.joined(separator: "\n\n") + "\n}"
    }
}
