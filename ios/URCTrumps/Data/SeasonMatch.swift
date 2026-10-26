import Foundation

struct SeasonMatch: Codable, Hashable, Identifiable, Sendable {
    let matchID: Int
    let round: Int
    let kickoff: String
    let status: String
    let home: Bool
    let venue: String?
    let opponent: String
    let scoreFor: Int?
    let scoreAgainst: Int?
    let played: Bool
    let minutes: Int?
    let tries: Int?
    let points: Int?
    let tackles: Int?
    let missedTackles: Int?
    let turnoversWon: Int?
    let carries: Int?
    let metres: Int?
    let cleanBreaks: Int?
    let defendersBeaten: Int?
    let offloads: Int?
    let tryAssists: Int?

    var id: Int { matchID }
    var isResult: Bool { status == "result" }

    enum CodingKeys: String, CodingKey {
        case round, kickoff, status, home, venue, opponent, played, minutes, tries, points
        case tackles, carries, metres, offloads
        case matchID = "match_id"
        case scoreFor = "score_for"
        case scoreAgainst = "score_against"
        case missedTackles = "missed_tackles"
        case turnoversWon = "turnovers_won"
        case cleanBreaks = "clean_breaks"
        case defendersBeaten = "defenders_beaten"
        case tryAssists = "try_assists"
    }

    var result: MatchResult? {
        guard isResult, let scoreFor, let scoreAgainst else { return nil }
        if scoreFor > scoreAgainst { return .win }
        return scoreFor == scoreAgainst ? .draw : .loss
    }

    /// Kickoff times are stored as "yyyy-MM-dd HH:mm:ss" (UTC).
    var kickoffDate: Date? {
        try? Date(kickoff.replacingOccurrences(of: " ", with: "T") + "Z", strategy: .iso8601)
    }
}
