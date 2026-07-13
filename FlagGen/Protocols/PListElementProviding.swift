//
//  FlagGen
//  Created by Scott Symes
//

import Foundation

protocol PListElementProviding {
    var pListElements: [PListElement] { get }
}

/// A property that generates its own separate `.plist` file
protocol PListSubFileProviding {
    var filename: String { get }

    var subFileFeatureFlags: Any { get }
}
