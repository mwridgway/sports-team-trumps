import SwiftUI

/// One match: header (round, opponent, W/D/L glass chip) and, if played, a stat line.
struct MatchRow: View {
    let match: SeasonMatch
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(match.played ? Color.chalk : Color.chalkDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 8)
                    if match.played {
                        chip
                    } else {
                        Text("Didn't play").font(.footnote.weight(.semibold)).foregroundStyle(Color.chalkDim)
                    }
                }
                if match.played {
                    summary
                    if isExpanded { details }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!match.played)
        .accessibilityHint(match.played ? (isExpanded ? "Collapse stats" : "Show all stats") : "")
    }

    /// Matches he missed carry the score in the title; played ones show it as a glass chip.
    private var title: String {
        var text = "R\(match.round) · \(match.home ? "v" : "at") \(match.opponent)"
        if !match.played, let result = match.result, let scoreFor = match.scoreFor, let scoreAgainst = match.scoreAgainst {
            text += " · \(result.rawValue) \(scoreFor)–\(scoreAgainst)"
        }
        return text
    }

    private var chip: some View {
        Group {
            if let result = match.result, let scoreFor = match.scoreFor, let scoreAgainst = match.scoreAgainst {
                Text("\(result.rawValue) \(scoreFor)–\(scoreAgainst)")
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 26)
                    .glassEffect(.regular, in: .capsule)
                    .accessibilityLabel("\(spoken(result)) \(scoreFor) \(scoreAgainst)")
            }
        }
    }

    private func spoken(_ result: MatchResult) -> String {
        switch result {
        case .win: "Won"
        case .draw: "Drew"
        case .loss: "Lost"
        }
    }

    private var summary: some View {
        let items: [(Int, String, Bool)] = [
            (match.minutes ?? 0, "min", false), (match.tackles ?? 0, "tackles", true),
            (match.missedTackles ?? 0, "missed", false), (match.carries ?? 0, "carries", false),
            (match.metres ?? 0, "m", false),
        ] + ((match.tries ?? 0) > 0 ? [(match.tries ?? 0, (match.tries ?? 0) == 1 ? "try" : "tries", true)] : [])
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { ForEach(items.indices, id: \.self) { statLabel(items[$0]) } }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) { ForEach(items.indices.prefix(3), id: \.self) { statLabel(items[$0]) } }
                HStack(spacing: 12) { ForEach(items.indices.dropFirst(3), id: \.self) { statLabel(items[$0]) } }
            }
        }
        .font(.callout)
        .foregroundStyle(Color(hex: "#c9d4cc"))
    }

    private func statLabel(_ item: (Int, String, Bool)) -> some View {
        HStack(spacing: 3) {
            Text(item.0, format: .number).bold().foregroundStyle(item.2 ? Color.amber : Color.chalk)
            Text(item.1)
        }
        .fixedSize()
    }

    private var details: some View {
        let rows: [(String, Int?)] = [
            ("Tries", match.tries), ("Points", match.points), ("Turnovers won", match.turnoversWon),
            ("Clean breaks", match.cleanBreaks), ("Defenders beaten", match.defendersBeaten),
            ("Offloads", match.offloads), ("Try assists", match.tryAssists),
        ]
        return Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            ForEach(rows.indices, id: \.self) { index in
                GridRow {
                    Text(rows[index].0).foregroundStyle(Color.chalkDim)
                    Text(rows[index].1.map(String.init) ?? "–").bold().foregroundStyle(Color.chalk)
                        .gridColumnAlignment(.trailing)
                }
            }
        }
        .font(.footnote)
        .padding(.top, 4)
    }
}
