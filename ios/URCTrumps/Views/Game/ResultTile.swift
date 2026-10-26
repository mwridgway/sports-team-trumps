import SwiftUI

struct ResultTile: View {
    let title: String
    let value: String
    var detail: String?
    var small = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(Color.chalkDim)
            Text(value)
                .font(.display(small ? 30 : 40, .extraBold))
                .textCase(small ? .uppercase : nil)
                .foregroundStyle(Color.chalk)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let detail { Text(detail).font(.footnote).foregroundStyle(Color.chalkDim) }
        }
        .frame(maxWidth: .infinity, minHeight: small ? 88 : 72, alignment: .topLeading)
        .padding(14)
        .background(Color.pitchLight, in: .rect(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.pitchLine) }
        .accessibilityElement(children: .combine)
    }
}
