import SwiftUI

/// Glass pill used for chips and badges floating above content.
struct GlassChip: View {
    let text: String
    var systemImage: String?
    var tint: Color?
    var clear = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage).accessibilityHidden(true) }
            Text(text).lineLimit(1)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .glassEffect(glass, in: .capsule)
    }

    private var glass: Glass {
        let base: Glass = clear ? .clear : .regular
        return tint.map { base.tint($0) } ?? base
    }
}
