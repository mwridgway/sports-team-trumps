import Testing
@testable import URCTrumps

struct DealTests {
    @Test func dealsTwoHalvesOfSixteenWithNoDuplicates() {
        var rng = SeededGenerator(seed: 1)
        let deal = Deck.deal(players: Fixtures.pool(100), leaders: ["tackles": [100]], using: &rng)
        #expect(deal.user.count == 16)
        #expect(deal.cpu.count == 16)
        #expect(Set((deal.user + deal.cpu).map(\.id)).count == 32)
    }

    @Test func alwaysIncludesEveryLeaderIncludingTies() {
        let leaders = ["tackles": [100], "tries": [3, 4], "height": [4]]
        for seed in 0..<50 {
            var rng = SeededGenerator(seed: UInt64(seed))
            let deal = Deck.deal(players: Fixtures.pool(100), leaders: leaders, using: &rng)
            let ids = Set((deal.user + deal.cpu).map(\.id))
            #expect([100, 3, 4].allSatisfy(ids.contains))
        }
    }

    @Test func sameSeedGivesSameDeal() {
        var a = SeededGenerator(seed: 9), b = SeededGenerator(seed: 9)
        let first = Deck.deal(players: Fixtures.pool(60), leaders: [:], using: &a)
        let second = Deck.deal(players: Fixtures.pool(60), leaders: [:], using: &b)
        #expect(first.user.map(\.id) == second.user.map(\.id))
    }
}

struct HandTests {
    private func game(user: [Player], cpu: [Player]) -> Game {
        Game(categories: Fixtures.categories, userPile: user, cpuPile: cpu)
    }

    @Test func userWinTakesBothCardsToTheBottom() {
        var g = game(user: [Fixtures.player(1, tackles: 9), Fixtures.player(2)], cpu: [Fixtures.player(3, tackles: 5), Fixtures.player(4)])
        let hand = g.play(Fixtures.tackles)
        #expect(hand.outcome == .win(.user))
        #expect(g.userPile.map(\.id) == [2, 1, 3])
        #expect(g.cpuPile.map(\.id) == [4])
    }

    @Test func cpuWinTakesBothCardsAndThePick() {
        var g = game(user: [Fixtures.player(1, tackles: 1), Fixtures.player(2)], cpu: [Fixtures.player(3, tackles: 5), Fixtures.player(4)])
        g.play(Fixtures.tackles)
        #expect(g.cpuPile.map(\.id) == [4, 3, 1])
        #expect(g.picker == .cpu)
    }

    @Test func drawGoesToTheRuckAndNextWinnerCollectsIt() {
        var g = game(
            user: [Fixtures.player(1, tackles: 5), Fixtures.player(2, tackles: 9), Fixtures.player(5)],
            cpu: [Fixtures.player(3, tackles: 5), Fixtures.player(4, tackles: 1), Fixtures.player(6)]
        )
        let draw = g.play(Fixtures.tackles)
        #expect(draw.outcome == .draw)
        #expect(g.ruck.map(\.id) == [1, 3])
        #expect(g.picker == .user)
        #expect(g.userPile.count == 2 && g.cpuPile.count == 2)

        let win = g.play(Fixtures.tackles)
        #expect(win.outcome == .win(.user))
        #expect(g.ruck.isEmpty)
        #expect(g.userPile.map(\.id) == [5, 2, 4, 1, 3])
        #expect(g.peakRuck == 2)
    }

    @Test func winnerOfLastHandPicksNext() {
        var g = game(user: [Fixtures.player(1), Fixtures.player(2)], cpu: [Fixtures.player(3, tackles: 4), Fixtures.player(4)])
        #expect(g.picker == .user)
        g.play(Fixtures.tackles)
        #expect(g.picker == .cpu)
        let hand = g.play(Fixtures.tackles)
        #expect(hand.picker == .cpu)
    }

    @Test func gameEndsWhenOneSideHasEveryCard() {
        var g = game(user: [Fixtures.player(1, tackles: 9)], cpu: [Fixtures.player(2)])
        #expect(!g.isOver)
        g.play(Fixtures.tackles)
        #expect(g.isOver)
        #expect(g.result == .win)
        #expect(g.cpuPile.isEmpty)
    }

    @Test func endingEarlyAwardsTheLargerPile() {
        var g = game(user: [Fixtures.player(1), Fixtures.player(2), Fixtures.player(3)], cpu: [Fixtures.player(4)])
        g.endEarly()
        #expect(g.isOver && g.result == .win)
        var tied = game(user: [Fixtures.player(1)], cpu: [Fixtures.player(2)])
        tied.endEarly()
        #expect(tied.result == .draw)
    }

    @Test func fullGameWithSeededDealTerminatesAndConservesCards() {
        var rng = SeededGenerator(seed: 3)
        var g = Game(categories: Fixtures.categories, userPile: [], cpuPile: [])
        let deal = Deck.deal(players: Fixtures.pool(60), leaders: [:], using: &rng)
        g = Game(categories: Fixtures.categories, userPile: deal.user, cpuPile: deal.cpu)
        var hands = 0
        while !g.isOver, hands < 5000 {
            g.play(Fixtures.categories[hands % 2])
            #expect(g.userPile.count + g.cpuPile.count + g.ruck.count == 32)
            hands += 1
        }
        #expect(g.isOver)
    }

    @Test func summaryCountsHandsAndFindsBestCall() {
        var g = game(
            user: [Fixtures.player(1, tackles: 9), Fixtures.player(2, tackles: 9), Fixtures.player(5)],
            cpu: [Fixtures.player(3, tackles: 5), Fixtures.player(4, tackles: 5), Fixtures.player(6)]
        )
        g.play(Fixtures.tackles)
        g.play(Fixtures.tackles)
        let summary = GameSummary(game: g)
        #expect(summary.handsWon == 2)
        #expect(summary.bestCall?.category == Fixtures.tackles)
        #expect(summary.bestCall?.won == 2 && summary.bestCall?.called == 2)
        #expect(summary.cardOfMatch?.won == 1)
    }
}
