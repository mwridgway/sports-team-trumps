import SwiftUI

extension Category {
    func formatted(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }

    /// "Tries, 37" / "Height, 188 cm" for VoiceOver.
    func spoken(_ value: Int) -> String {
        "\(label), \(formatted(value))" + (unit.map { " \($0 == "m" ? "metres" : $0 == "cm" ? "centimetres" : "kilograms")" } ?? "")
    }
}
