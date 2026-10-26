import SwiftUI

/// Club colour runs under the status bar and HUD; the headshot sits below them so the face is clear.
struct PhotoWithScrims: View {
    let player: Player

    var body: some View {
        ZStack {
            player.clubTint.ignoresSafeArea(edges: .top)
            PlayerPhoto(image: player.image)
                .background(Color(hex: "#f1f3f2"))
                .padding(.top, HUDMetrics.clearance)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 130)
            }
        }
    }
}
