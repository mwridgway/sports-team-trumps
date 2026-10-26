import SwiftUI

/// Mown-stripe pitch background used on the non-card screens.
struct PitchBackground: View {
    var body: some View {
        Canvas { context, size in
            let stripe: CGFloat = 46
            var x: CGFloat = 0
            var odd = false
            while x < size.width {
                let rect = CGRect(x: x, y: 0, width: stripe, height: size.height)
                context.fill(Path(rect), with: .color(odd ? .pitchLight : .pitch))
                x += stripe
                odd.toggle()
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
