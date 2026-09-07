import UIKit

// The harness exercises production UIKit views without starting Gecko/JIT in a
// simulator. Only engine/store dependencies and the unrelated address field are
// substituted here; navigation, toolbar, menus and layout code are real sources.
struct DownloadStoreSummary {
    var showsToolbarButton = false
    var aggregateProgress = 0.0
    var activeCount = 0
}
enum LibrarySection { case bookmarks, history, downloads, settings }
enum NavigationHistoryStore { struct HistoryItem {} }
enum TabOverview {
    enum Mode: Int { case privateTabs, regularTabs }
}
final class ToolbarButtonMenus {
    enum NavigationDirection { case back, forward }
    func installNavigationMenus(on: UIButton, forwardButton: UIButton, itemsProvider: @escaping (NavigationDirection) -> [NavigationHistoryStore.HistoryItem], onSelect: @escaping (NavigationDirection, Int) -> Void) {}
    func installLibraryMenus(on: [UIButton], onSelect: @escaping (LibrarySection) -> Void) {}
    func installTabOverviewMenus(on: [UIButton], tabCountProvider: @escaping () -> Int, onCloseAllTabs: @escaping () -> Void, onCloseTab: @escaping () -> Void, onNewPrivateTab: @escaping () -> Void, onNewTab: @escaping () -> Void) {}
}
final class VariableBlurView: UIView {
    enum Direction { case up }
    var direction: Direction = .up
}
@available(iOS 26.0, *)
extension UIGlassEffect {
    static func nonAdaptive(style: Style) -> UIGlassEffect { UIGlassEffect(style: style) }
}
final class AddressBar: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 44).isActive = true
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 22
        let label = UILabel()
        label.text = "Search or enter address"
        label.textColor = .secondaryLabel
        label.frame = CGRect(x: 16, y: 0, width: 250, height: 44)
        addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError() }
}
