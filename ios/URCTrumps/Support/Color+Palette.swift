import SwiftUI

extension Color {
    init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt32(digits, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    static let pitch = Color(hex: "#0d1a14")
    static let pitchLight = Color(hex: "#13251c")
    static let pitchLine = Color(hex: "#2b4436")
    static let chalk = Color(hex: "#e9efe9")
    static let chalkDim = Color(hex: "#b5c4ba")
    static let cardPaper = Color(hex: "#f5f7f4")
    static let ink = Color(hex: "#121815")
    static let inkDim = Color(hex: "#5d6a62")
    static let amber = Color(hex: "#f2b134")
    static let amberInk = Color(hex: "#3a2700")

    /// Club band colour, nudged darker so white text keeps 4.5:1 contrast.
    static func club(_ hex: String) -> Color {
        Color(hex: hex).mix(with: .black, by: 0.14)
    }
}
