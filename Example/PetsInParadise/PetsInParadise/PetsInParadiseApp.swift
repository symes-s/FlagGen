//
//  FlagGen
//  Created by Scott Symes
//

import SwiftUI

@main
struct PetsInParadiseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var flags = AppFeatureFlags.shared
    @StateObject private var cart = CartStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(flags)
                .environmentObject(cart)
        }
    }
}
