import SwiftUI

/// Pause button and score pill, floating as glass over the photo.
struct ScoreHUD: View {
    let game: Game
    var userToPick = false
    let onEndGame: () -> Void
    let onRules: () -> Void
    let onQuit: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                Menu {
                    Button("End game", systemImage: "flag.checkered", role: .destructive, action: onEndGame)
                    Button("How to play", systemImage: "questionmark.circle", action: onRules)
                    Button("Quit to home", systemImage: "house", action: onQuit)
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .contentShape(.circle)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Pause game")

                scorePill
            }
        }
    }

    private var scorePill: some View {
        HStack {
            HStack(spacing: 6) {
                if userToPick { Circle().fill(Color.amber).frame(width: 8, height: 8) }
                Text("You").font(.footnote.weight(.semibold))
                Text(game.userPile.count, format: .number).font(.title3.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                Text("Ruck").font(.footnote.weight(.semibold))
                Text(game.ruck.count, format: .number).font(.callout.bold())
            }
            HStack(spacing: 6) {
                Text("CPU").font(.footnote.weight(.semibold))
                Text(game.cpuPile.count, format: .number).font(.title3.bold())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .monospacedDigit()
        .padding(.horizontal, 16)
        .frame(height: 46)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "You \(game.userPile.count) cards, ruck \(game.ruck.count), CPU \(game.cpuPile.count) cards"
        )
    }
}
