import SwiftUI

/// Full time: result, tallies, best call and card of the match.
struct ResultView: View {
    let game: Game
    let summary: GameSummary
    let library: Library
    let onFile: (Player) -> Void
    let onRematch: () -> Void
    let onHome: () -> Void

    @State private var shown = false

    private var result: GameResult { game.result ?? .draw }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                GlassChip(text: "Full time · \(summary.handsPlayed) hands")
                VStack(alignment: .leading, spacing: -8) {
                    Text(headline.0)
                    Text(headline.1).foregroundStyle(Color.amber)
                }
                .font(.display(70))
                .textCase(.uppercase)
                .foregroundStyle(Color.chalk)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            tiles
            if let standout = summary.cardOfMatch { cardOfMatch(standout) }
            Spacer(minLength: 0)
            GlassEffectContainer(spacing: 10) {
                VStack(spacing: 10) {
                    Button(action: onRematch) {
                        Text("Rematch").font(.headline).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.amber)
                    .foregroundStyle(Color.amberInk)
                    Button(action: onHome) {
                        Text("Home").font(.headline).foregroundStyle(Color.chalk).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.extraLarge)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background { PitchBackground() }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .sensoryFeedback(.success, trigger: shown) { _, now in now && result == .win }
        .onAppear { shown = true }
    }

    private var headline: (String, String) {
        switch result {
        case .win: ("You", "win")
        case .lose: ("You", "lose")
        case .draw: ("All", "square")
        }
    }

    private var tiles: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                ResultTile(title: "Cards", value: "\(game.userPile.count)–\(game.cpuPile.count)")
                ResultTile(title: "Hands won", value: "\(summary.handsWon)")
            }
            GridRow {
                if let call = summary.bestCall {
                    ResultTile(title: "Best call", value: call.category.label, detail: "won \(call.won) of \(call.called)", small: true)
                } else {
                    ResultTile(title: "Best call", value: "None", detail: "no hands won on your pick", small: true)
                }
                ResultTile(
                    title: "Biggest ruck",
                    value: summary.peakRuck > 0 ? "\(summary.peakRuck) cards" : "None",
                    detail: summary.draws == 0 ? "no draws" : summary.draws == 1 ? "after 1 draw" : "after \(summary.draws) draws",
                    small: true
                )
            }
        }
    }

    private func cardOfMatch(_ standout: GameSummary.StandoutCard) -> some View {
        let player = standout.player
        let theme = CardTheme(isFoil: library.isLeader(player))
        return HStack(spacing: 14) {
            Color.clear
                .frame(width: 92, height: 116)
                .background { PlayerPhoto(image: player.image) }
                .clipShape(.rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text("Card of the match").font(.footnote.weight(.bold)).foregroundStyle(theme.dim)
                Text(player.lastName)
                    .font(.display(32)).textCase(.uppercase).foregroundStyle(theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text("Won \(standout.won) \(standout.won == 1 ? "hand" : "hands") for you, mostly on \(standout.category.label.lowercased()).")
                    .font(.footnote).foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Player file") { onFile(player) }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.ink)
                    .frame(minHeight: 44, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background { theme.background.clipShape(.rect(cornerRadius: 18)) }
    }
}
