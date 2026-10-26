import SwiftUI

/// Bio facts.
struct ProfileTab: View {
    let player: Player

    private var born: String {
        guard let text = player.dateOfBirth,
              let date = try? Date(text, strategy: .iso8601.year().month().day()) else { return "–" }
        return "\(date.formatted(date: .long, time: .omitted)) (age \(player.age))"
    }

    var body: some View {
        let rows: [(String, String)] = [
            ("Born", born),
            ("Birth country", player.birthCountry ?? "–"),
            ("National team", player.nationalTeam ?? "–"),
            ("Position", player.positionTitle),
            ("Club", player.club),
            ("URC appearances", "\(player.appearances)"),
        ]
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline) {
                    Text(rows[index].0).font(.callout).foregroundStyle(Color.chalkDim)
                    Spacer(minLength: 12)
                    Text(rows[index].1).font(.callout.weight(.semibold)).foregroundStyle(Color.chalk)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)
                if index < rows.count - 1 { Divider().overlay(Color.pitchLine) }
            }
        }
        .background(Color.pitchLight, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.pitchLine) }
    }
}
