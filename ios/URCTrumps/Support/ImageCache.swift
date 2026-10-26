import SwiftUI

/// Shared in-memory cache for headshots (480px JPEGs bundled under GameData/headshots).
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    func cached(_ name: String) -> UIImage? { cache.object(forKey: name as NSString) }

    func load(_ name: String) async -> UIImage? {
        if let hit = cached(name) { return hit }
        guard let url = Bundle.main.resourceURL?.appending(path: "GameData/headshots/\(name)"),
              let image = UIImage(contentsOfFile: url.path)?.preparingForDisplay() else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}
