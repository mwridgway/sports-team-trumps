import CoreMotion
import SwiftUI

/// Silver foil gradient that shimmers slowly with device motion (static under Reduce Motion).
struct FoilBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                gradient(shift: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let drift = sin(context.date.timeIntervalSinceReferenceDate / 3) * 0.12
                    gradient(shift: drift + TiltSource.shared.tilt * 0.35)
                }
                .onAppear { TiltSource.shared.start() }
                .onDisappear { TiltSource.shared.stop() }
            }
        }
        .accessibilityHidden(true)
    }

    private func gradient(shift: Double) -> some View {
        LinearGradient(
            colors: [
                Color(hex: "#eef1f4"), Color(hex: "#c7cfd7"), Color(hex: "#f6f8fa"),
                Color(hex: "#aab4be"), Color(hex: "#e4e8ec"),
            ],
            startPoint: UnitPoint(x: -0.3 + shift, y: 0),
            endPoint: UnitPoint(x: 1.3 + shift, y: 1)
        )
    }
}
