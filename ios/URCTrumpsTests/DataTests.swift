import Testing
@testable import URCTrumps

@MainActor
struct DataTests {
    @Test func decodesTheBundledSnapshot() async throws {
        let library = try await Fixtures.realLibrary()
        #expect(library.players.count > 500)
        #expect(library.categories.count == 6)
        #expect(!library.data.season.isEmpty)
        #expect(library.players.allSatisfy { player in library.categories.allSatisfy { player.stats[$0.key] != nil } })
        for category in library.categories {
            #expect(!library.leaders(in: category).isEmpty)
        }
    }

    @Test func leadersAreHighestInTheirCategory() async throws {
        let library = try await Fixtures.realLibrary()
        for category in library.categories {
            let top = library.players.map { $0.value(for: category) }.max()
            #expect(library.leaders(in: category).allSatisfy { $0.value(for: category) == top })
        }
    }

    @Test func realDealHasThirtyTwoCardsAndEveryLeader() async throws {
        let library = try await Fixtures.realLibrary()
        let leaderIDs = Set(library.data.leaders.values.flatMap { $0 })
        var rng = SeededGenerator(seed: 11)
        let game = Game(library: library, using: &rng)
        #expect(game.userPile.count == 16 && game.cpuPile.count == 16)
        #expect(leaderIDs.isSubset(of: Set(game.deck.map(\.id))))
    }

    @Test func seasonMatchesParse() async throws {
        let library = try await Fixtures.realLibrary()
        let matches = library.players.flatMap(\.seasonMatches)
        #expect(matches.allSatisfy { $0.kickoffDate != nil })
        #expect(matches.contains { $0.result == .win })
        let headshot = try #require(library.players.first?.image)
        #expect(await ImageCache.shared.load(headshot) != nil)
    }
}
