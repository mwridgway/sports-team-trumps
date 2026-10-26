import SwiftUI

enum PlayerFileTab: String, CaseIterable, Identifiable {
    case season = "Season"
    case career = "Career"
    case profile = "Profile"

    var id: String { rawValue }
}
