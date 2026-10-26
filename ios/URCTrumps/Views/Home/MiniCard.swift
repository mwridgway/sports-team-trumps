import SwiftUI

/// A small decorative card for the fan on the home screen.
struct MiniCard: View {
    let player: Player
    let foil: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(player.clubTint).frame(height: 22)
            Color.clear.background { PlayerPhoto(image: player.image) }
            Text(player.lastName)
                .font(.display(foil ? 25 : 21))
                .textCase(.uppercase)
                .lineLimit(1).minimumScaleFactor(0.5)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10).padding(.vertical, 6)
        }
        .background { if foil { FoilBackground() } else { Color.cardPaper } }
        .clipShape(.rect(cornerRadius: 16))
        .overlay { if foil { RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#d7dde3"), lineWidth: 2) } }
        .shadow(color: .black.opacity(0.5), radius: 14, y: 10)
    }
}
