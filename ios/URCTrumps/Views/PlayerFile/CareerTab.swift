import SwiftUI

/// URC totals for each season from the career data.
struct CareerTab: View {
    let player: Player

    var body: some View {
        VStack(spacing: 0) {
            ForEach(player.career, id: \.season) { season in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(season.season).font(.callout.weight(.semibold))
                        Spacer()
                        Text(season.team).font(.footnote).foregroundStyle(Color.chalkDim).lineLimit(1)
                    }
                    Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            figure(season.appearances, "games")
                            figure(season.minutes, "minutes")
                            figure(season.points, "points")
                            figure(season.tries, "tries")
                        }
                        GridRow {
                            figure(season.tackles, "tackles")
                            figure(season.metres, "metres")
                            figure(season.carries, "carries")
                            figure(season.turnoversWon, "turnovers")
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                if season.season != player.career.last?.season { Divider().overlay(Color.pitchLine) }
            }
            if player.career.isEmpty {
                Text("No earlier URC seasons on record.").font(.callout).foregroundStyle(Color.chalkDim).padding(14)
            }
        }
        .background(Color.pitchLight, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.pitchLine) }
    }

    private func figure(_ value: Int, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value, format: .number).font(.title3.bold()).monospacedDigit().foregroundStyle(Color.chalk)
            Text(label).font(.caption).foregroundStyle(Color.chalkDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
