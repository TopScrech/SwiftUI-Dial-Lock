import SwiftUI

struct BackgroundBlur: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.2, blue: 0.45),
                    Color(red: 0.15, green: 0.42, blue: 0.42),
                    Color(red: 0.55, green: 0.4, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}
