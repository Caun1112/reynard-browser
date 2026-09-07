import UIKit

/// Physical right-hand placement is independent of the language's reading direction.
enum RightHandLayout {
    static var isEnabled: Bool { UIDevice.current.userInterfaceIdiom == .phone }
    static let touchSize: CGFloat = 48
    static let spacing: CGFloat = 8
    static let edgeInset: CGFloat = 12
    static let controlWidth: CGFloat = touchSize * 3 + spacing * 2

    static func align(_ stack: UIStackView) {
        stack.semanticContentAttribute = .forceLeftToRight
        stack.spacing = spacing
        stack.alignment = .center
    }
}
