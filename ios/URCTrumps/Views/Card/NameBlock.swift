import SwiftUI

struct NameBlock: View {
    let player: Player
    let theme: CardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(player.firstName)
                .font(.label(15))
                .tracking(1.2)
                .foregroundStyle(theme.dim)
            Text(player.lastName)
                .font(.display(40))
                .foregroundStyle(theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .textCase(.uppercase)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
