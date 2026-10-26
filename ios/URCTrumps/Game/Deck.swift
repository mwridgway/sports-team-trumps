enum Deck {
    static let size = 32

    /// Every category leader, topped up at random from the pool to `size`, shuffled and split in two.
    static func deal<G: RandomNumberGenerator>(
        players: [Player],
        leaders: [String: [Int]],
        size: Int = Deck.size,
        using rng: inout G
    ) -> (user: [Player], cpu: [Player]) {
        let leaderIDs = Set(leaders.values.flatMap { $0 })
        let picked = players.filter { leaderIDs.contains($0.id) }
        let rest = players.filter { !leaderIDs.contains($0.id) }.shuffled(using: &rng)
        let deck = (picked + rest.prefix(max(0, size - picked.count))).shuffled(using: &rng)
        let half = deck.count / 2
        return (Array(deck[..<half]), Array(deck[half...]))
    }
}
