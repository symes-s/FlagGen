//
//  FlagGen
//  Created by Scott Symes
//

import SwiftUI

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("Scene Will Enter Foreground")
        AppFeatureFlags.shared.updateValues()
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }
}
