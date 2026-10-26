import Foundation
import Observation

/// Drives one game against the computer: wraps the rules and sequences the screens.
@MainActor @Observable
final class GameModel: Hashable {
    nonisolated static func == (lhs: GameModel, rhs: GameModel) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }

    enum Phase {
        case choosing                 // user picks a category
        case cpuPicking(Category)     // computer's choice is on show before the reveal
        case revealed(HandRecord)
        case over
    }

    let id = UUID()
    let difficulty: Difficulty
    private(set) var game: Game
    private(set) var phase: Phase = .choosing
    private let strategy: CPUStrategy
    private var rng: SeededGenerator

    init(library: Library, difficulty: Difficulty, seed: UInt64 = .random(in: .min ... .max)) {
        var rng = SeededGenerator(seed: seed)
        game = Game(library: library, using: &rng)
        self.rng = rng
        self.difficulty = difficulty
        strategy = CPUStrategy(difficulty: difficulty, statBook: library.statBook)
    }

    init(library: Library, difficulty: Difficulty, game: Game, seed: UInt64) {
        self.game = game
        rng = SeededGenerator(seed: seed)
        self.difficulty = difficulty
        strategy = CPUStrategy(difficulty: difficulty, statBook: library.statBook)
    }

    var summary: GameSummary { GameSummary(game: game) }

    /// The user taps a stat on their card.
    func pick(_ category: Category) {
        phase = .revealed(game.play(category))
    }

    /// The computer's announced pick is played.
    func playCPUPick(_ category: Category) {
        phase = .revealed(game.play(category))
    }

    /// Moves on from a reveal to the next hand, or to full time.
    func next() {
        guard !game.isOver, let card = game.cpuCard else {
            phase = .over
            return
        }
        if game.picker == .user {
            phase = .choosing
        } else {
            phase = .cpuPicking(strategy.choose(
                card: card, categories: game.categories, candidates: game.cpuCandidates, using: &rng
            ))
        }
    }

    func endGame() {
        game.endEarly()
        phase = .over
    }
}
