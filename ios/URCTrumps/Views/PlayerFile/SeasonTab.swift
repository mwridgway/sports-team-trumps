import SwiftUI

/// This season's matches for the player's club, most recent result first.
struct SeasonTab: View {
    let player: Player
    @State private var expanded: Set<Int> = []

    private var results: [SeasonMatch] {
        player.seasonMatches.filter(\.isResult).sorted { $0.round > $1.round }
    }

    private var nextFixture: SeasonMatch? {
        player.seasonMatches.filter { !$0.isResult }.min { $0.round < $1.round }
    }

    private var played: [SeasonMatch] { results.filter(\.played) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            tiles
            if let nextFixture { nextChip(nextFixture) }
            if results.isEmpty {
                Text("No matches played yet this season.")
                    .font(.callout).foregroundStyle(Color.chalkDim)
            } else {
                VStack(spacing: 0) {
                    ForEach(results) { match in
                        MatchRow(match: match, isExpanded: expanded.contains(match.id)) { toggle(match) }
                        if match.id != results.last?.id { Divider().overlay(Color.pitchLine) }
                    }
                }
                .background(Color.pitchLight, in: .rect(cornerRadius: 16))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.pitchLine) }
            }
        }
    }

    private var tiles: some View {
        HStack(alignment: .top, spacing: 8) {
            SeasonTile(value: "\(played.count)", suffix: "/\(results.count)", label: "games")
            SeasonTile(value: "\(played.reduce(0) { $0 + ($1.minutes ?? 0) })", label: "minutes")
            SeasonTile(value: "\(played.reduce(0) { $0 + ($1.tackles ?? 0) })", label: "tackles", accent: true)
            SeasonTile(value: "\(played.reduce(0) { $0 + ($1.carries ?? 0) })", label: "carries")
        }
    }

    private func nextChip(_ match: SeasonMatch) -> some View {
        var parts = ["R\(match.round)", "\(match.home ? "v" : "at") \(match.opponent)"]
        if let date = match.kickoffDate {
            parts.append(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
        }
        return HStack(spacing: 8) {
            Text("Next").bold().foregroundStyle(Color.amber)
            Text(parts.joined(separator: " · ")).lineLimit(1)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .frame(minHeight: 34)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }

    private func toggle(_ match: SeasonMatch) {
        withAnimation(.snappy) {
            if expanded.contains(match.id) { expanded.remove(match.id) } else { expanded.insert(match.id) }
        }
    }
}
