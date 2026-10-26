/// How the computer chooses a category when it is its turn to pick.
struct CPUStrategy: Sendable {
    let difficulty: Difficulty
    let statBook: StatBook

    /// - Parameters:
    ///   - card: the computer's top card.
    ///   - candidates: cards the user's top card could be (those the computer hasn't seen).
    func choose<G: RandomNumberGenerator>(
        card: Player,
        categories: [Category],
        candidates: [Player],
        using rng: inout G
    ) -> Category {
        switch difficulty {
        case .easy:
            return categories.randomElement(using: &rng) ?? categories[0]
        case .medium:
            return best(of: categories) { statBook.percentile(of: card.value(for: $0), in: $0) }
        case .hard:
            guard !candidates.isEmpty else { return choosePercentile(card, categories) }
            return best(of: categories) { category in
                let mine = card.value(for: category)
                let wins = candidates.count { $0.value(for: category) < mine }
                // Percentile only breaks ties between equal win rates.
                return Double(wins) / Double(candidates.count) + statBook.percentile(of: mine, in: category) * 1e-6
            }
        }
    }

    private func choosePercentile(_ card: Player, _ categories: [Category]) -> Category {
        best(of: categories) { statBook.percentile(of: card.value(for: $0), in: $0) }
    }

    private func best(of categories: [Category], by score: (Category) -> Double) -> Category {
        categories.max { score($0) < score($1) } ?? categories[0]
    }
}
