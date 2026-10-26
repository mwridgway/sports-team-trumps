import SwiftUI

/// One game against the computer: turn, reveal and full time.
struct GameView: View {
    let model: GameModel
    let library: Library
    let onRematch: () -> Void
    let onHome: () -> Void

    @State private var filePlayer: Player?
    @State private var choices: [Player] = []
    @State private var isChoosing = false

    var body: some View {
        ZStack {
            switch model.phase {
            case .choosing:
                turn(cpuPick: nil)
            case .cpuPicking(let category):
                turn(cpuPick: category)
                    .task(id: model.game.hands.count) {
                        try? await Task.sleep(for: .seconds(1.6))
                        guard !Task.isCancelled else { return }
                        withAnimation(.snappy) { model.playCPUPick(category) }
                    }
            case .revealed(let record):
                RevealView(
                    game: model.game, record: record, library: library,
                    onFiles: openFiles, onNext: { withAnimation(.snappy) { model.next() } },
                    onEndGame: endGame, onQuit: onHome
                )
            case .over:
                ResultView(
                    game: model.game, summary: model.summary, library: library,
                    onFile: { filePlayer = $0 }, onRematch: onRematch, onHome: onHome
                )
            }
        }
        .background(Color.pitch.ignoresSafeArea())
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .sheet(item: $filePlayer) { PlayerFileSheet(player: $0, library: library) }
        .confirmationDialog("Which player file?", isPresented: $isChoosing, titleVisibility: .visible) {
            ForEach(choices) { player in
                Button(player.fullName) { filePlayer = player }
            }
        }
    }

    private func turn(cpuPick: Category?) -> some View {
        TurnView(
            game: model.game, library: library, cpuPick: cpuPick,
            onPick: { category in withAnimation(.snappy) { model.pick(category) } },
            onFile: { filePlayer = $0 }, onEndGame: endGame, onQuit: onHome
        )
        .transition(.opacity)
    }

    private func openFiles(_ players: [Player]) {
        choices = players
        isChoosing = true
    }

    private func endGame() { withAnimation(.snappy) { model.endGame() } }
}
