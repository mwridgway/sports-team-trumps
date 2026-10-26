import SwiftUI

struct PlayerFileHeader: View {
    let player: Player
    let leads: [Category]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            player.clubTint
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Color.clear
                    .frame(width: 230)
                    .background { PlayerPhoto(image: player.image) }
            }
            LinearGradient(
                stops: [.init(color: player.clubTint, location: 0.36), .init(color: player.clubTint.opacity(0), location: 0.78)],
                startPoint: .leading, endPoint: .trailing
            )
            LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
                .frame(maxHeight: .infinity, alignment: .top)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(player.club) · \(player.positionTitle) · \(player.age)")
                    .font(.subheadline.weight(.semibold))
                Text("\(player.firstName)\n\(player.lastName)")
                    .font(.display(46))
                    .textCase(.uppercase)
                    .lineSpacing(-8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .accessibilityAddTraits(.isHeader)
                if let lead = leads.first {
                    GlassChip(
                        text: "No.1 \(lead.label.lowercased()) in the URC" + (leads.count > 1 ? " +\(leads.count - 1)" : ""),
                        systemImage: "crown.fill", tint: Color(hex: "#e1e7ed").opacity(0.3)
                    )
                    .padding(.top, 8)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .frame(height: 270)
        .clipped()
    }
}
