//
//  FlagGen
//  Created by Scott Symes
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        PetListView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppFeatureFlags.shared)
        .environmentObject(CartStore())
}
