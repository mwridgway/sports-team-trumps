import SwiftUI

/// Half-screen card: photo and club colour on the left, name and the contested stat on the right.
struct RevealCard: View {
    let player: Player
    let label: String
    let category: Category
    let value: Int
    let library: Library
    let lost: Bool
    let photoWidth: CGFloat
    let topInset: Bool

    /// The top card keeps its face clear of the HUD; the bottom one runs under the home indicator.
    private var photo: some View {
        ZStack {
            if topInset { player.clubTint.ignoresSafeArea(edges: .top) }
            PlayerPhoto(image: player.image)
                .background(Color(hex: "#f1f3f2"))
                .padding(.top, topInset ? HUDMetrics.clearance : 0)
        }
        .ignoresSafeArea(edges: topInset ? [] : .bottom)
    }

    var body: some View {
        let leads = library.leads(player)
        let theme = CardTheme(isFoil: !leads.isEmpty)
        HStack(spacing: 0) {
            Color.clear
                .frame(width: photoWidth)
                .background { photo }
            Rectangle().fill(player.clubTint).frame(width: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(label) · \(player.club) · \(player.positionTitle)")
                    .font(.label(13)).tracking(1.2).textCase(.uppercase).foregroundStyle(theme.dim)
                    .lineLimit(2)
                Text(player.firstName)
                    .font(.label(15)).tracking(0.9).textCase(.uppercase).foregroundStyle(theme.dim)
                Text(player.lastName)
                    .font(.display(32)).textCase(.uppercase).foregroundStyle(theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(category.label).font(.label(18)).tracking(0.7).textCase(.uppercase).foregroundStyle(theme.dim)
                    Text(category.formatted(value))
                        .font(.display(lost ? 52 : 68, lost ? .extraBold : .black))
                        .strikethrough(lost, color: .inkDim)
                        .foregroundStyle(lost ? Color(hex: "#59625d") : theme.ink)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.top, topInset ? 112 : 40)
            .padding(.bottom, topInset ? 36 : 96)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
        .background {
            theme.background.ignoresSafeArea(edges: topInset ? .top : .bottom)
        }
        .saturation(lost ? 0.4 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(player.fullName), \(player.club). \(category.spoken(value))")
    }
}
