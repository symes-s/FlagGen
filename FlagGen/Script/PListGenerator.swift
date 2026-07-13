//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

struct PListGenerator {
    enum Error: Swift.Error {
        case emptyElementsList
    }

    func generateFeaturesPlistJson(filepath: URL, from object: Any, asPreferenceSpecifier: Bool) throws {
        let allPListElements: [PListElement] = Mirror(reflecting: object)
            .children
            .compactMap { ($1 as? PListElementProviding)?.pListElements }
            .sorted(by: { $0.count < $1.count })
            .flatMap { $0 }

        guard !allPListElements.isEmpty else {
            throw Error.emptyElementsList
        }

        let encoder = JSONEncoder()
        // encoder.outputFormatting = .prettyPrinted
        let data: Data
        if asPreferenceSpecifier {
            data = try RootLevelDict(allPListElements).encoded(by: encoder)
        } else {
            data = try allPListElements.encoded(by: encoder)
        }
        try data.write(to: filepath, options: .atomic)
        // print("Generated intermediate plist json file at\t\(filepath.absoluteString.replacingOccurrences(of: "file://", with: ""))\n")
    }
}

struct RootLevelDict {
    let key: String = "PreferenceSpecifiers"
    let values: [PListElement]

    init(_ values: [PListElement]) {
        self.values = values
    }

    func encoded(by encoder: JSONEncoder) throws -> Data {
        var data = Data("{".utf8)
        data += try encoder.encode(key)
        data += Data(":".utf8)
        data += try values.encoded(by: encoder)
        data += Data("}".utf8)
        return data
    }
}
