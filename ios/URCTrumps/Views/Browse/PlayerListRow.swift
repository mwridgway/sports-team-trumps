import SwiftUI

struct PlayerListRow: View {
    let player: Player
    let leads: [Category]

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 48, height: 48)
                .background { PlayerPhoto(image: player.image) }
                .clipShape(.circle)
                .overlay { Circle().stroke(player.clubTint, lineWidth: 2) }
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName).font(.body.weight(.semibold)).foregroundStyle(Color.chalk)
                Text("\(player.club) · \(player.positionTitle)").font(.subheadline).foregroundStyle(Color.chalkDim)
            }
            Spacer(minLength: 8)
            if !leads.isEmpty {
                LeaderCrown()
                    .foregroundStyle(LinearGradient(colors: [.white, Color(hex: "#9aa5b0")], startPoint: .top, endPoint: .bottom))
                    .font(.title3)
            }
        }
        .frame(minHeight: 56)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityValue(leads.isEmpty ? "" : "Leader: " + leads.map(\.label).joined(separator: ", "))
    }
}
