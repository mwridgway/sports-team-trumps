/// Highlights for the full-time screen.
struct GameSummary: Sendable {
    struct Call: Sendable {
        let category: Category
        let won: Int
        let called: Int
    }

    struct StandoutCard: Sendable {
        let player: Player
        let won: Int
        let category: Category
    }

    let handsPlayed: Int
    let handsWon: Int
    let draws: Int
    let peakRuck: Int
    /// The category the user called most successfully.
    let bestCall: Call?
    /// The user's card that won the most hands.
    let cardOfMatch: StandoutCard?

    init(game: Game) {
        handsPlayed = game.hands.count
        handsWon = game.hands.count { $0.outcome == .win(.user) }
        draws = game.hands.count { $0.outcome == .draw }
        peakRuck = game.peakRuck

        let calls = Dictionary(grouping: game.hands.filter { $0.picker == .user }, by: \.category)
            .map { Call(category: $0.key, won: $0.value.count { $0.outcome == .win(.user) }, called: $0.value.count) }
        bestCall = calls.filter { $0.won > 0 }.max { a, b in
            (a.won, Double(a.won) / Double(a.called), b.category.key) < (b.won, Double(b.won) / Double(b.called), a.category.key)
        }

        let winsByCard = Dictionary(grouping: game.hands.filter { $0.outcome == .win(.user) }, by: \.userCard)
        let top = winsByCard.max { a, b in (a.value.count, b.key.id) < (b.value.count, a.key.id) }
        cardOfMatch = top.map { player, hands in
            let byCategory = Dictionary(grouping: hands, by: \.category)
            let category = byCategory.max { a, b in (a.value.count, b.key.key) < (b.value.count, a.key.key) }!.key
            return StandoutCard(player: player, won: hands.count, category: category)
        }
    }
}
