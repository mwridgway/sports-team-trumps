import SwiftUI

struct SeasonTile: View {
    let value: String
    var suffix: String?
    let label: String
    var accent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.display(30, .extraBold, relativeTo: .title)).foregroundStyle(accent ? Color.amber : Color.chalk)
                if let suffix { Text(suffix).font(.callout).foregroundStyle(Color.chalkDim) }
            }
            Text(label).font(.caption).foregroundStyle(Color.chalkDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
