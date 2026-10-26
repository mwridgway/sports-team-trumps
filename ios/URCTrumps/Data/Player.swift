import Foundation

struct Player: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let firstName: String
    let lastName: String
    let club: String
    let clubShort: String
    let clubColor: String
    let position: String
    let positionGroup: String
    let age: Int
    let dateOfBirth: String?
    let birthCountry: String?
    let nationalTeam: String?
    let appearances: Int
    let stats: [String: Int]
    let image: String?
    let career: [CareerSeason]
    let seasonMatches: [SeasonMatch]

    var fullName: String { "\(firstName) \(lastName)" }

    func value(for category: Category) -> Int { stats[category.key] ?? 0 }

    enum CodingKeys: String, CodingKey {
        case id, club, position, age, appearances, stats, image, career
        case firstName = "first_name"
        case lastName = "last_name"
        case clubShort = "club_short"
        case clubColor = "club_color"
        case positionGroup = "position_group"
        case dateOfBirth = "date_of_birth"
        case birthCountry = "birth_country"
        case nationalTeam = "national_team"
        case seasonMatches = "season_matches"
    }
}
