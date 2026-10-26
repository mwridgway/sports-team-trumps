import CoreMotion
import SwiftUI

/// Crown mark used for "No.1" leaders.
struct LeaderCrown: View {
    var body: some View {
        Image(systemName: "crown.fill")
            .symbolRenderingMode(.hierarchical)
            .accessibilityHidden(true)
    }
}
