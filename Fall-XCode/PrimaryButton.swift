

import Foundation
import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(Color("AccentColour"))
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(Color("SecondaryColour")) 
                .buttonStyle(.bordered)
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }
}
