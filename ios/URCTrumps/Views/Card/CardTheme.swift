import SwiftUI

/// Paper card for everyone, silver foil for category leaders.
struct CardTheme {
    let isFoil: Bool

    var ink: Color { .ink }
    var dim: Color { isFoil ? Color(hex: "#3b4741") : .inkDim }
    var rule: Color { isFoil ? Color(hex: "#a9b3bd") : Color(hex: "#dfe5e0") }

    @ViewBuilder
    var background: some View {
        if isFoil { FoilBackground() } else { Color.cardPaper }
    }
}
