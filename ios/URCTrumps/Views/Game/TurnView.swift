import SwiftUI

/// The user's card filling the screen. Rows are live when it's the user's pick;
/// when the computer picks, its choice is highlighted and announced.
struct TurnView: View {
    let game: Game
    let library: Library
    var cpuPick: Category?
    let onPick: (Category) -> Void
    let onFile: (Player) -> Void
    let onEndGame: () -> Void
    let onRules: () -> Void
    let onQuit: () -> Void

    var body: some View {
        if let card = game.userCard {
            let leads = library.leads(card)
            let theme = CardTheme(isFoil: !leads.isEmpty)
            VStack(spacing: 0) {
                photoSection(card, leads: leads)
                ClubBand(player: card)
                NameBlock(player: card, theme: theme)
                VStack(spacing: 0) {
                    ForEach(library.categories) { category in
                        StatRow(
                            category: category, value: card.value(for: category), theme: theme,
                            isLeading: leads.contains(category), isChosen: cpuPick == category,
                            isEnabled: cpuPick == nil
                        ) { onPick(category) }
                    }
                }
                .frame(maxHeight: 6 * 72)
                .padding(.horizontal, 6)
                .padding(.top, 4)
            }
            .background { theme.background.ignoresSafeArea() }
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
        }
    }

    private func photoSection(_ card: Player, leads: [Category]) -> some View {
        Color.clear
            .frame(minHeight: 220, maxHeight: .infinity)
            .background { PhotoWithScrims(player: card) }
            .overlay(alignment: .top) {
                ScoreHUD(game: game, userToPick: cpuPick == nil, onEndGame: onEndGame, onRules: onRules, onQuit: onQuit)
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }
            .overlay(alignment: .bottom) {
                GlassEffectContainer(spacing: 8) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            turnChip
                            if let lead = leads.first { leaderBadge(lead, extra: leads.count - 1) }
                            GlassChip(text: card.originLine, clear: true)
                        }
                        Spacer(minLength: 8)
                        Button { onFile(card) } label: {
                            Label("Player file", systemImage: "person.text.rectangle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                    }
                }
                .padding(12)
            }
    }

    private var turnChip: some View {
        Group {
            if let cpuPick {
                GlassChip(text: "CPU picks \(cpuPick.label)", systemImage: "cpu", tint: .amber.opacity(0.7))
            } else {
                GlassChip(text: "Your pick · tap a stat", systemImage: "hand.tap")
            }
        }
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func leaderBadge(_ category: Category, extra: Int) -> some View {
        HStack(spacing: 8) {
            LeaderCrown()
            Text("No.1 \(category.label)" + (extra > 0 ? " +\(extra)" : ""))
                .font(.display(20, .black, relativeTo: .title3))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .glassEffect(.regular.tint(Color(hex: "#e1e7ed").opacity(0.35)), in: .capsule)
        .accessibilityElement(children: .combine)
    }
}
