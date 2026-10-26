import SwiftUI

/// One tappable statistic row (at least 44pt tall).
struct StatRow: View {
    let category: Category
    let value: Int
    let theme: CardTheme
    var isLeading = false
    var isChosen = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button { if isEnabled { action() } } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if isLeading { LeaderCrown().foregroundStyle(Color.amber) }
                Text(category.label)
                    .font(.label(22, isLeading ? .semiBold : .medium))
                    .tracking(0.9)
                    .textCase(.uppercase)
                    .foregroundStyle(isLeading ? Color(hex: "#f4f6f8") : isChosen ? Color.amberInk : theme.dim)
                Spacer(minLength: 8)
                if isLeading {
                    Text("Most in URC")
                        .font(.label(13, .medium))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(Color(hex: "#c8d0d8"))
                }
                valueText
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: .infinity)
            .background { rowBackground }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isEnabled)
        .overlay(alignment: .bottom) {
            if !isLeading && !isChosen { Rectangle().fill(theme.rule).frame(height: 1).padding(.horizontal, 10) }
        }
        .accessibilityLabel(category.spoken(value))
        .accessibilityValue(isLeading ? "Most in the URC" : "")
    }

    private var valueText: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(category.formatted(value))
                .font(.label(isLeading ? 26 : 22, .bold))
                .monospacedDigit()
            if let unit = category.unit {
                Text(unit).font(.label(15, .medium))
            }
        }
        .foregroundStyle(isLeading ? Color(hex: "#f4f6f8") : isChosen ? Color.amberInk : theme.ink)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isLeading {
            RoundedRectangle(cornerRadius: 12).fill(Color.ink)
                .overlay { if isChosen { RoundedRectangle(cornerRadius: 12).stroke(Color.amber, lineWidth: 3) } }
        } else if isChosen {
            RoundedRectangle(cornerRadius: 12).fill(Color.amber)
        }
    }
}
