import UIKit

extension UIBarButtonItem {
    /// System items don't expose their generated title/image. Give the reachable
    /// presentation explicit metadata while keeping the original target/action.
    static func reachableSystemItem(_ systemItem: SystemItem, target: Any?, action: Selector?) -> UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: systemItem, target: target, action: action)
        switch systemItem {
        case .done: item.accessibilityLabel = NSLocalizedString("Done", comment: "")
        case .cancel: item.accessibilityLabel = NSLocalizedString("Cancel", comment: "")
        case .save: item.accessibilityLabel = NSLocalizedString("Save", comment: "")
        case .edit: item.accessibilityLabel = NSLocalizedString("Edit", comment: "")
        case .add:
            item.accessibilityLabel = NSLocalizedString("Add", comment: "")
            if RightHandLayout.isEnabled { item.image = UIImage(systemName: "plus") }
        case .trash:
            item.accessibilityLabel = NSLocalizedString("Delete", comment: "")
            if RightHandLayout.isEnabled { item.image = UIImage(systemName: "trash") }
        case .close:
            item.accessibilityLabel = NSLocalizedString("Close", comment: "")
            if RightHandLayout.isEnabled { item.image = UIImage(systemName: "xmark") }
        default: break
        }
        return item
    }
}

/// A real 48pt control backed by the live navigation item, rather than a copy of
/// its action or enabled state. Menus, form validation and Edit/Done stay in sync.
final class ReachableBarButton: UIButton {
    private let item: UIBarButtonItem
    private var observations: [NSKeyValueObservation] = []

    init(item: UIBarButtonItem) {
        self.item = item
        super.init(frame: .zero)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.lineBreakMode = .byTruncatingTail
        layer.cornerRadius = 12
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        heightAnchor.constraint(equalToConstant: RightHandLayout.touchSize).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: RightHandLayout.touchSize).isActive = true
        addTarget(self, action: #selector(activate), for: .touchUpInside)
        observations = [
            item.observe(\.isEnabled, options: [.new]) { [weak self] _, _ in self?.refresh() },
            item.observe(\.title, options: [.new]) { [weak self] _, _ in self?.refresh() },
            item.observe(\.image, options: [.new]) { [weak self] _, _ in self?.refresh() },
            item.observe(\.tintColor, options: [.new]) { [weak self] _, _ in self?.refresh() },
            item.observe(\.action, options: [.new]) { [weak self] _, _ in self?.refresh() },
        ]
        if #available(iOS 14.0, *) {
            observations.append(item.observe(\.menu, options: [.new]) { [weak self] _, _ in self?.refresh() })
        }
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? .tertiarySystemFill : .quaternarySystemFill }
    }

    func refresh() {
        isEnabled = item.isEnabled
        alpha = item.isEnabled ? 1 : 0.35
        tintColor = item.tintColor ?? .label
        setTitleColor(tintColor, for: .normal)
        setImage(item.image, for: .normal)
        let title = item.title?.isEmpty == false ? item.title : item.accessibilityLabel
        setTitle(item.image == nil ? title : nil, for: .normal)
        accessibilityLabel = item.accessibilityLabel ?? item.title
        accessibilityIdentifier = item.accessibilityIdentifier
        backgroundColor = .quaternarySystemFill
        if #available(iOS 14.0, *) {
            if menu !== item.menu { menu = item.menu }
            showsMenuAsPrimaryAction = item.menu != nil && item.action == nil
        }
    }

    @objc private func activate() {
        guard item.isEnabled, let action = item.action else { return }
        UIApplication.shared.sendAction(action, to: item.target, from: item, for: nil)
    }
}
