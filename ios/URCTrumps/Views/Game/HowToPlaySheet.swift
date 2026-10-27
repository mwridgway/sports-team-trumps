import SwiftUI

/// A short paged walkthrough of the rules. Shown before the first game, and from the pause menu.
struct HowToPlaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private struct Step: Identifiable {
        let id: Int
        let systemImage: String
        let title: String
        let text: String
    }

    private static let steps = [
        Step(
            id: 0, systemImage: "rectangle.stack.fill", title: "A pack of \(Deck.size)",
            text: "Each game deals \(Deck.size) URC players: \(Deck.size / 2) to you and \(Deck.size / 2) to the computer. "
                + "Win all \(Deck.size) cards to win the game."
        ),
        Step(
            id: 1, systemImage: "hand.tap.fill", title: "Call a stat",
            text: "Tap the stat where your top card is strongest. The higher number takes both cards. "
                + "A draw puts both cards in the ruck, and the next winner takes them all."
        ),
        Step(
            id: 2, systemImage: "arrow.trianglehead.2.clockwise", title: "Win, and you call again",
            text: "The winner of each hand picks the stat for the next one. "
                + "Keep winning and you keep calling."
        ),
        Step(
            id: 3, systemImage: "cpu", title: "Lose, and the computer calls",
            text: "When the computer wins a hand, it picks the stat for you. "
                + "It keeps picking, hand after hand, until it gets one wrong. Watch the score at the top."
        ),
    ]

    private var isLast: Bool { page == Self.steps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            Text("How to play")
                .font(.label(20, .bold, relativeTo: .headline))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(Color.amber)
                .padding(.top, 28)
                .accessibilityAddTraits(.isHeader)

            TabView(selection: $page) {
                ForEach(Self.steps) { step in
                    stepView(step).tag(step.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if isLast { dismiss() } else { withAnimation(.snappy) { page += 1 } }
            } label: {
                Text(isLast ? "Let's play" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.amber)
            .foregroundStyle(Color.amberInk)
            .controlSize(.extraLarge)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .overlay(alignment: .topTrailing) {
            if !isLast {
                Button("Skip") { dismiss() }
                    .buttonStyle(.glass)
                    .foregroundStyle(Color.chalk)
                    .padding(.trailing, 14)
                    .padding(.top, 14)
            }
        }
        .foregroundStyle(Color.chalk)
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.pitch)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func stepView(_ step: Step) -> some View {
        VStack(spacing: 20) {
            Image(systemName: step.systemImage)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Color.amber)
                .frame(height: 84)
                .accessibilityHidden(true)
            Text(step.title)
                .font(.display(40, relativeTo: .largeTitle))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
            Text(step.text)
                .font(.body)
                .foregroundStyle(Color.chalkDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
