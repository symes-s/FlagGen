//
//  FlagGen
//  Created by Scott Symes
//

import SwiftUI

struct WishlistButton: View {
    @State private var isWishlisted = false

    var body: some View {
        Button {
            isWishlisted.toggle()
        } label: {
            Image(systemName: isWishlisted ? "heart.fill" : "heart")
                .foregroundStyle(isWishlisted ? .pink : .secondary)
        }
        .buttonStyle(.plain)
    }
}
