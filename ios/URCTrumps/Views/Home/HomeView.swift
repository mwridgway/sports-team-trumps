import SwiftUI

/// Title, the fan of cards, and the way in to a game or the player list.
struct HomeView: View {
    let library: Library
    @Binding var difficulty: Difficulty
    let onPlay: () -> Void
    let onBrowse: () -> Void

    private var fan: [Player] {
        let tackleLeader = library.leaders(in: library.categories[2]).first
        let others = library.players.filter { !library.isLeader($0) }.sorted { $0.appearances > $1.appearances }
        return [others.first, tackleLeader, others.dropFirst().first].compactMap { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GlassChip(text: "\(library.data.season) · after round \(library.data.latestRound)")
            title
            cardFan.frame(maxHeight: .infinity)
            buttons
            Text(library.dataLine)
                .font(.footnote)
                .foregroundStyle(Color.chalkDim)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background { PitchBackground() }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("URC")
            Text("Trumps").foregroundStyle(Color.amber)
        }
        .font(.display(62))
        .lineSpacing(-10)
        .textCase(.uppercase)
        .foregroundStyle(Color.chalk)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var cardFan: some View {
        ZStack {
            if fan.count == 3 {
                MiniCard(player: fan[0], foil: false).frame(width: 146, height: 232)
                    .rotationEffect(.degrees(-9)).offset(x: -96, y: 14)
                MiniCard(player: fan[2], foil: false).frame(width: 146, height: 232)
                    .rotationEffect(.degrees(8)).offset(x: 96, y: 10)
                MiniCard(player: fan[1], foil: true).frame(width: 166, height: 266)
                    .shadow(color: .black.opacity(0.6), radius: 20, y: 14)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private var buttons: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button(action: onPlay) {
                        Text("Play the computer").font(.headline).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.amber)
                    .foregroundStyle(Color.amberInk)

                    Menu {
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(Difficulty.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(difficulty.rawValue)
                            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                        }
                        .font(.headline)
                        .frame(minWidth: 86)
                    }
                    .buttonStyle(.glass)
                    .foregroundStyle(Color.chalk)
                    .accessibilityLabel("Difficulty")
                    .accessibilityValue(difficulty.rawValue)
                }
                Button(action: onBrowse) {
                    HStack {
                        Text("Browse the players")
                        Spacer()
                        Text(library.players.count, format: .number).foregroundStyle(Color.chalkDim)
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .foregroundStyle(Color.chalk)
            }
            .controlSize(.extraLarge)
        }
    }
}
