import SwiftUI

/// Club-coloured strip: club and position on the left, age on the right.
struct ClubBand: View {
    let player: Player

    var body: some View {
        HStack {
            Text("\(player.club) · \(player.positionTitle)")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            Text("AGE \(player.age)")
                .font(.display(20, .extraBold, relativeTo: .title3))
        }
        .font(.label(16, .bold))
        .textCase(.uppercase)
        .tracking(1.6)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(player.clubTint)
        .accessibilityElement(children: .combine)
    }
}
