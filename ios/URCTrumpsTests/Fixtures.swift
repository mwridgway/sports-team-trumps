import Foundation
@testable import URCTrumps

enum Fixtures {
    static let tackles = Category(key: "tackles", label: "Tackles", unit: nil)
    static let tries = Category(key: "tries", label: "Tries", unit: nil)
    static let categories = [tackles, tries]

    static func player(_ id: Int, tackles: Int = 0, tries: Int = 0) -> Player {
        Player(
            id: id, firstName: "P", lastName: "\(id)", club: "Club", clubShort: "CLB", clubColor: "#112233",
            position: "wing", positionGroup: "back", age: 25, dateOfBirth: nil, birthCountry: nil, nationalTeam: nil,
            appearances: 20, stats: ["tackles": tackles, "tries": tries], image: nil, career: [], seasonMatches: []
        )
    }

    /// A pool of `count` players whose stats rise with the id.
    static func pool(_ count: Int) -> [Player] {
        (1...count).map { player($0, tackles: $0 * 10, tries: ($0 * 7) % 13) }
    }

    @MainActor
    static func realLibrary() async throws -> Library {
        Library(data: try await GameData.loadBundled())
    }
}
