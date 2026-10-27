#if DEBUG
import SwiftUI

/// Debug-only launch arguments to jump straight to a screen:
/// `-scenario home|turn|leader|cpupick|reveal|result|browse|file|career|profile`, `-seed N`.
/// Games open with the How to play sheet until it has been seen once; pass `-hasSeenHowToPlay YES`
/// to skip it, or `-hasSeenHowToPlay NO` to show it again.
struct DebugScenario {
    struct File: Identifiable {
        let player: Player
        let tab: PlayerFileTab
        var id: Int { player.id }
    }

    let name: String
    let seed: UInt64

    static var current: DebugScenario? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-scenario"), index + 1 < args.count else { return nil }
        let seed = args.firstIndex(of: "-seed").flatMap { Int(args[$0 + 1]) }.map(UInt64.init) ?? 7
        return DebugScenario(name: args[index + 1], seed: seed)
    }

    private static let timoneyID = 193134

    @MainActor
    func apply(
        library: Library, difficulty: Difficulty,
        path: Binding<[RootView.Route]>, file: Binding<File?>
    ) {
        let timoney = library.player(id: Self.timoneyID)
        switch name {
        case "turn":
            path.wrappedValue = [.game(GameModel(library: library, difficulty: difficulty, seed: seed))]
        case "leader":
            path.wrappedValue = [.game(leaderGame(library, difficulty))]
        case "reveal":
            let model = leaderGame(library, difficulty)
            model.pick(library.categories[2])
            path.wrappedValue = [.game(model)]
        case "cpupick":
            let model = GameModel(library: library, difficulty: difficulty, seed: seed)
            var steps = 0
            while !isCPUPicking(model.phase), !model.game.isOver, steps < 1500 {
                step(model, library)
                steps += 1
            }
            path.wrappedValue = [.game(model)]
        case "result":
            var model = autoplayed(library, difficulty, seed: seed)
            var next = seed
            while model.game.result != .win, next < seed + 50 {
                next += 1
                model = autoplayed(library, difficulty, seed: next)
            }
            path.wrappedValue = [.game(model)]
        case "browse":
            path.wrappedValue = [.browse]
        case "file", "career", "profile":
            if let timoney {
                file.wrappedValue = File(player: timoney, tab: name == "career" ? .career : name == "profile" ? .profile : .season)
            }
        default:
            break
        }
    }

    /// The user's top card is Nick Timoney, the tackles leader.
    @MainActor
    private func leaderGame(_ library: Library, _ difficulty: Difficulty) -> GameModel {
        var rng = SeededGenerator(seed: seed)
        let dealt = Game(library: library, using: &rng)
        var user = dealt.userPile, cpu = dealt.cpuPile
        if let timoney = library.player(id: Self.timoneyID) {
            if let index = cpu.firstIndex(of: timoney) { cpu[index] = user.removeFirst() } else { user.removeAll { $0 == timoney } }
            user.insert(timoney, at: 0)
        }
        let game = Game(categories: library.categories, userPile: user, cpuPile: cpu)
        return GameModel(library: library, difficulty: difficulty, game: game, seed: seed)
    }

    /// Advances one step; at the user's pick it chooses the category where their card ranks highest.
    @MainActor
    private func step(_ model: GameModel, _ library: Library) {
        switch model.phase {
        case .choosing:
            guard let card = model.game.userCard else { return }
            let percentile = { (category: Category) in library.statBook.percentile(of: card.value(for: category), in: category) }
            model.pick(library.categories.max { percentile($0) < percentile($1) }!)
        case .cpuPicking(let category):
            model.playCPUPick(category)
        case .revealed:
            model.next()
        case .over:
            break
        }
    }

    @MainActor
    private func autoplayed(_ library: Library, _ difficulty: Difficulty, seed: UInt64) -> GameModel {
        let model = GameModel(library: library, difficulty: difficulty, seed: seed)
        var steps = 0
        while case let phase = model.phase, !isOver(phase), steps < 1500 {
            step(model, library)
            steps += 1
        }
        if !model.game.isOver { model.endGame() }
        return model
    }

    private func isCPUPicking(_ phase: GameModel.Phase) -> Bool {
        if case .cpuPicking = phase { return true }
        return false
    }

    private func isOver(_ phase: GameModel.Phase) -> Bool {
        if case .over = phase { return true }
        return false
    }
}
#endif
