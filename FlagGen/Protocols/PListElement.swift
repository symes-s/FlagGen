//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

protocol PListElement: Encodable {
    var title: String? { get }
    var type: String { get }
    var defaultDescription: String? { get }
    func encoded() throws -> Data
    func encoded(by encoder: JSONEncoder) throws -> Data
}

extension PListElement {
    func encoded() throws -> Data {
        try encoded(by: JSONEncoder())
    }

    func encoded(by encoder: JSONEncoder) throws -> Data {
        try encoder.encode(self)
    }
}

extension PListValueElement {
    var defaultDescription: String? {
        String(describing: defaultValue)
    }
}
