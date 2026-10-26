import Foundation

/// Indexes over `GameData` that the game and the screens share.
struct Library: Sendable {
    let data: GameData
    let statBook: StatBook
    /// Leaders first, then by surname: the order the browse list shows.
    let browseOrder: [Player]
    private let byID: [Int: Player]
    private let leaderCategories: [Int: [Category]]

    init(data: GameData) {
        self.data = data
        statBook = StatBook(players: data.players, categories: data.categories)
        byID = Dictionary(uniqueKeysWithValues: data.players.map { ($0.id, $0) })
        var map: [Int: [Category]] = [:]
        for category in data.categories {
            for id in data.leaders[category.key] ?? [] { map[id, default: []].append(category) }
        }
        leaderCategories = map
        browseOrder = data.players.sorted { lhs, rhs in
            let (l, r) = (map[lhs.id] != nil, map[rhs.id] != nil)
            if l != r { return l }
            return (lhs.lastName, lhs.firstName) < (rhs.lastName, rhs.firstName)
        }
    }

    var categories: [Category] { data.categories }
    var players: [Player] { data.players }

    func player(id: Int) -> Player? { byID[id] }

    /// Categories in which this player has the most in the URC (ties all lead).
    func leads(_ player: Player) -> [Category] { leaderCategories[player.id] ?? [] }

    func isLeader(_ player: Player) -> Bool { leaderCategories[player.id] != nil }

    func leaders(in category: Category) -> [Player] {
        (data.leaders[category.key] ?? []).compactMap { byID[$0] }
    }

    var clubs: [String] { Array(Set(data.players.map(\.club))).sorted() }

    var dataLine: String {
        "Season \(data.season) · after round \(data.latestRound) · \(data.players.count) players"
    }
}
