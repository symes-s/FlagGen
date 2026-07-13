//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

extension Collection where Element == PListElement {
    func encoded(by encoder: JSONEncoder) throws -> Data {
        // Each element is `Encodable`, but the Collection is not.
        // Manually converting to JSON Array by:
        // converting each element to `Data` then join
        // with ',' delimiter and surround with '[' & ']'
        let data = try self.map { try $0.encoded(by: encoder) }
        let isPrettyPrint = encoder.outputFormatting.contains(.prettyPrinted)
        let separator = isPrettyPrint ? ",\n" : ","
        let openBracket = isPrettyPrint ? "[\n" : "["
        let closeBracket = isPrettyPrint ? "\n]" : "]"
        let arrayContents = Data(data.joined(separator: separator.data(using: .utf8)!))
        return openBracket.data(using: .utf8)! + arrayContents + closeBracket.data(using: .utf8)!
    }

    func json(by encoder: JSONEncoder) -> String? {
        guard let data = try? encoded(by: encoder) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
