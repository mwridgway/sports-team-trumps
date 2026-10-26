import Foundation

struct CareerSeason: Codable, Hashable, Sendable {
    let season: String
    let team: String
    let appearances: Int
    let minutes: Int
    let points: Int
    let tries: Int
    let tackles: Int
    let metres: Int
    let carries: Int
    let turnoversWon: Int

    enum CodingKeys: String, CodingKey {
        case season, team, appearances, minutes, points, tries, tackles, metres, carries
        case turnoversWon = "turnovers_won"
    }
}
