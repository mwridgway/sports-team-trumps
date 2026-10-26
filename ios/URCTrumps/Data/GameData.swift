import Foundation

/// The decoded contents of GameData/urc.json.
struct GameData: Decodable, Sendable {
    let season: String
    let latestRound: Int
    let poolSize: Int
    let categories: [Category]
    let leaders: [String: [Int]]
    let players: [Player]

    enum CodingKeys: String, CodingKey {
        case season, categories, leaders, players
        case latestRound = "latest_round"
        case poolSize = "pool_size"
    }

    /// Reads and decodes the bundled snapshot. Runs off the main actor.
    static func loadBundled(from bundle: Bundle = .main) async throws -> GameData {
        guard let url = bundle.url(forResource: "urc", withExtension: "json", subdirectory: "GameData") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(GameData.self, from: Data(contentsOf: url))
    }
}
