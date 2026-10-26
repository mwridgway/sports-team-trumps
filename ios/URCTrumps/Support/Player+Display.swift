import SwiftUI

extension Player {
    /// "fly-half" -> "Fly-half"
    var positionTitle: String { position.prefix(1).uppercased() + position.dropFirst() }

    var clubTint: Color { .club(clubColor) }

    /// Home nation first: the national team if capped, otherwise the birth country.
    var originLine: String {
        "\(nationalTeam ?? birthCountry ?? "URC") · \(appearances) URC games"
    }
}
