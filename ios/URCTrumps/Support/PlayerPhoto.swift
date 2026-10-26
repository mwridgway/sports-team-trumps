import SwiftUI

/// A headshot filling its frame, anchored towards the top so faces stay in view.
struct PlayerPhoto: View {
    let image: String?
    @State private var loaded: UIImage?

    init(image: String?) {
        self.image = image
        _loaded = State(initialValue: image.flatMap { ImageCache.shared.cached($0) })
    }

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                if let loaded {
                    Image(uiImage: loaded)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
                }
            }
            .clipped()
            .task(id: image) {
                guard let image, loaded == nil else { return }
                loaded = await ImageCache.shared.load(image)
            }
            .accessibilityHidden(true)
    }
}
