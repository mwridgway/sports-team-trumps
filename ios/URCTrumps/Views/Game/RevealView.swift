import SwiftUI

/// Both cards face up with the result banner on the seam.
struct RevealView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let game: Game
    let record: HandRecord
    let library: Library
    let onFiles: ([Player]) -> Void
    let onNext: () -> Void
    let onEndGame: () -> Void
    let onQuit: () -> Void

    @State private var faceUp = false

    var body: some View {
        VStack(spacing: 0) {
            RevealCard(
                player: record.cpuCard, label: "CPU", category: record.category, value: record.cpuValue,
                library: library, lost: record.outcome == .win(.user), photoWidth: 150, topInset: true
            )
            .rotation3DEffect(.degrees(faceUp || reduceMotion ? 0 : 90), axis: (x: 1, y: 0, z: 0), anchor: .bottom)
            .opacity(faceUp || !reduceMotion ? 1 : 0)
            RevealCard(
                player: record.userCard, label: "You", category: record.category, value: record.userValue,
                library: library, lost: record.outcome == .win(.cpu), photoWidth: 170, topInset: false
            )
        }
        .background(Color.pitch.ignoresSafeArea())
        .overlay { banner.scaleEffect(faceUp ? 1 : 0.8).opacity(faceUp ? 1 : 0) }
        .overlay(alignment: .top) {
            ScoreHUD(game: game, onEndGame: onEndGame, onQuit: onQuit)
                .padding(.horizontal, 12)
                .padding(.top, 4)
        }
        .overlay(alignment: .bottom) { actions }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .sensoryFeedback(.impact, trigger: faceUp) { _, shown in shown && record.outcome == .win(.user) }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.55, bounce: 0.25)) { faceUp = true }
            AccessibilityNotification.Announcement(spokenResult).post()
        }
    }

    private var title: String {
        switch record.outcome {
        case .win(.user): "You take the hand"
        case .win(.cpu): "CPU takes the hand"
        case .draw: "Draw · into the ruck"
        }
    }

    private var spokenResult: String {
        "\(title). \(record.category.label), \(record.userValue) against \(record.cpuValue)."
    }

    private var banner: some View {
        HStack(spacing: 14) {
            Text(title).font(.headline)
            Text("\(record.userValue) v \(record.cpuValue)")
                .font(.display(28, .black, relativeTo: .title))
        }
        .foregroundStyle(record.outcome == .win(.user) ? Color.amberInk : .white)
        .padding(.horizontal, 22)
        .frame(minHeight: 56)
        .glassEffect(
            record.outcome == .win(.user) ? .regular.tint(.amber.opacity(0.9)) : .regular,
            in: .capsule
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenResult)
    }

    private var actions: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button { onFiles([record.userCard, record.cpuCard]) } label: {
                    Text("Both files").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .foregroundStyle(.white)
                Button(action: onNext) {
                    Text(game.isOver ? "Full time" : "Next card").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(.amber)
                .foregroundStyle(Color.amberInk)
            }
            .controlSize(.extraLarge)
            .font(.headline)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}
