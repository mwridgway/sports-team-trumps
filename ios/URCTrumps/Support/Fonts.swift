import SwiftUI

/// Card typography. Bundled fonts, registered through UIAppFonts.
extension Font {
    enum Display: String {
        case black = "BigShouldersDisplay-Black"
        case extraBold = "BigShouldersDisplay-ExtraBold"
    }

    enum Label: String {
        case medium = "BarlowCondensed-Medium"
        case semiBold = "BarlowCondensed-SemiBold"
        case bold = "BarlowCondensed-Bold"
    }

    static func display(_ size: CGFloat, _ weight: Display = .black, relativeTo style: TextStyle = .title) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static func label(_ size: CGFloat, _ weight: Label = .semiBold, relativeTo style: TextStyle = .body) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }
}
