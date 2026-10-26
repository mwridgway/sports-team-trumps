import Testing
@testable import URCTrumps

struct CPUTests {
    private let pool = Fixtures.pool(100)
    private var book: StatBook { StatBook(players: pool, categories: Fixtures.categories) }

    @Test func percentileRanksWithinThePool() {
        #expect(book.percentile(of: 1000, in: Fixtures.tackles) > 0.99)
        #expect(book.percentile(of: 0, in: Fixtures.tackles) == 0)
        #expect(abs(book.percentile(of: 505, in: Fixtures.tackles) - 0.5) < 0.02)
    }

    @Test func easyIsRandomButSeededAndValid() {
        let strategy = CPUStrategy(difficulty: .easy, statBook: book)
        let card = Fixtures.player(500, tackles: 1, tries: 1)
        var seen: Set<String> = []
        var rng = SeededGenerator(seed: 4)
        for _ in 0..<40 { seen.insert(strategy.choose(card: card, categories: Fixtures.categories, candidates: [], using: &rng).key) }
        #expect(seen == ["tackles", "tries"])
        var a = SeededGenerator(seed: 8), b = SeededGenerator(seed: 8)
        #expect(
            strategy.choose(card: card, categories: Fixtures.categories, candidates: [], using: &a)
                == strategy.choose(card: card, categories: Fixtures.categories, candidates: [], using: &b)
        )
    }

    @Test func mediumPicksTheCategoryRankedHighestInThePool() {
        let strategy = CPUStrategy(difficulty: .medium, statBook: book)
        var rng = SeededGenerator(seed: 1)
        let bigTackler = Fixtures.player(500, tackles: 990, tries: 0)
        #expect(strategy.choose(card: bigTackler, categories: Fixtures.categories, candidates: [], using: &rng) == Fixtures.tackles)
        let finisher = Fixtures.player(501, tackles: 0, tries: 12)
        #expect(strategy.choose(card: finisher, categories: Fixtures.categories, candidates: [], using: &rng) == Fixtures.tries)
    }

    @Test func hardPicksTheCategoryThatBeatsMostRemainingCards() {
        let strategy = CPUStrategy(difficulty: .hard, statBook: book)
        var rng = SeededGenerator(seed: 1)
        // Medium would favour tackles (top of the pool) but every unseen card out-tackles it.
        let card = Fixtures.player(500, tackles: 500, tries: 6)
        let unseen = (0..<5).map { Fixtures.player(600 + $0, tackles: 900, tries: 1) }
        #expect(strategy.choose(card: card, categories: Fixtures.categories, candidates: unseen, using: &rng) == Fixtures.tries)
    }

    @Test func gameOffersOnlyUnseenCardsAsCandidates() {
        let user = [Fixtures.player(1, tackles: 9), Fixtures.player(2), Fixtures.player(3)]
        let cpu = [Fixtures.player(4, tackles: 1), Fixtures.player(5)]
        var game = Game(categories: Fixtures.categories, userPile: user, cpuPile: cpu)
        #expect(Set(game.cpuCandidates.map(\.id)) == [1, 2, 3])
        game.play(Fixtures.tackles)
        #expect(Set(game.cpuCandidates.map(\.id)) == [2, 3])
    }
}
