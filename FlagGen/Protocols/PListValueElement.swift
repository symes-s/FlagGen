//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

protocol PListValueElement: PListElement {
    associatedtype DataType: Encodable
    var defaultValue: DataType { get }
    var key: String { get }
}
