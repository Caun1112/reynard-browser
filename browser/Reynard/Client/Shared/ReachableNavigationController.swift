import UIKit

/// Keeps the original navigation items (including menus and enabled state), but
/// presents them in a bottom dock on iPhone. iPad retains standard navigation.
class ReachableNavigationController: UINavigationController {
    private let dock = UIView()
    private let barLayout = UIStackView()
    private var rowsWidthConstraint: NSLayoutConstraint!
    private var rowsHeightConstraint: NSLayoutConstraint!
    private var barBottomConstraint: NSLayoutConstraint!
    private let rows = UIStackView()
    private let titleLabel = UILabel()
    private var titleHeightConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var dockHeightConstraint: NSLayoutConstraint!
    private var itemObservations: [NSKeyValueObservation] = []
    private weak var observedController: UIViewController?
    private weak var insetOwner: UIViewController?
    private var originalInsets = UIEdgeInsets.zero
    private var displayedItems: [UIBarButtonItem] = []
    private var keyboardOverlap: CGFloat = 0
    private var refreshPending = false
    private var isRefreshing = false

    private lazy var reachableBackItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named: "reynard.chevron.backward") ?? UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
        item.accessibilityLabel = NSLocalizedString("Back", comment: "")
        item.accessibilityIdentifier = "navigation.back"
        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard RightHandLayout.isEnabled else { return }
        super.setNavigationBarHidden(true, animated: false)
        super.setToolbarHidden(true, animated: false)
        dock.translatesAutoresizingMaskIntoConstraints = false
        dock.accessibilityIdentifier = "navigation.bottomDock"
        dock.backgroundColor = .secondarySystemGroupedBackground
        dock.isOpaque = true
        view.addSubview(dock)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.textAlignment = .right
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.accessibilityTraits = .header
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        rows.axis = .vertical
        rows.spacing = 4
        rows.translatesAutoresizingMaskIntoConstraints = false
        barLayout.axis = .horizontal
        barLayout.alignment = .center
        barLayout.spacing = 12
        barLayout.translatesAutoresizingMaskIntoConstraints = false
        barLayout.addArrangedSubview(titleLabel)
        barLayout.addArrangedSubview(rows)
        dock.addSubview(barLayout)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        dock.addSubview(separator)

        // The opaque surface reaches the physical bottom. Only the controls
        // are inset above the home indicator (or moved above the keyboard).
        bottomConstraint = dock.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        dockHeightConstraint = dock.heightAnchor.constraint(equalToConstant: 64)
        barBottomConstraint = barLayout.bottomAnchor.constraint(equalTo: dock.bottomAnchor, constant: -8)
        rowsWidthConstraint = rows.widthAnchor.constraint(equalToConstant: 104).withPriority(.defaultHigh)
        rowsHeightConstraint = rows.heightAnchor.constraint(equalToConstant: 48)
        titleHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: 28)
        NSLayoutConstraint.activate([
            dock.leftAnchor.constraint(equalTo: view.leftAnchor),
            dock.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomConstraint,
            dockHeightConstraint,
            barLayout.topAnchor.constraint(equalTo: dock.topAnchor, constant: 8),
            barLayout.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 16),
            barLayout.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -RightHandLayout.edgeInset),
            barBottomConstraint,
            titleHeightConstraint,
            rowsWidthConstraint,
            rowsHeightConstraint,
            rows.widthAnchor.constraint(lessThanOrEqualTo: barLayout.widthAnchor),
            separator.topAnchor.constraint(equalTo: dock.topAnchor),
            separator.leftAnchor.constraint(equalTo: dock.leftAnchor),
            separator.rightAnchor.constraint(equalTo: dock.rightAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleRefresh), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshReachableActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshReachableActions()
        if RightHandLayout.isEnabled {
            view.bringSubviewToFront(dock)
        }
    }

    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(RightHandLayout.isEnabled ? true : hidden, animated: animated)
    }

    override func setToolbarHidden(_ hidden: Bool, animated: Bool) {
        super.setToolbarHidden(RightHandLayout.isEnabled ? true : hidden, animated: animated)
    }

    func refreshReachableActions() {
        guard RightHandLayout.isEnabled, isViewLoaded, !isRefreshing,
              let controller = topViewController else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        observeItems(of: controller)

        var items: [UIBarButtonItem] = []
        if viewControllers.count > 1 { items.append(reachableBackItem) }
        items += controller.navigationItem.leftBarButtonItems ?? []
        items += controller.toolbarItems ?? []
        if let tabs = controller as? UITabBarController {
            items += tabs.selectedViewController?.toolbarItems ?? []
        }
        items += (controller.navigationItem.rightBarButtonItems ?? []).reversed()
        var seen = Set<ObjectIdentifier>()
        items = items.filter { item in
            let hasMenu: Bool
            if #available(iOS 14.0, *) { hasMenu = item.menu != nil } else { hasMenu = false }
            // Flexible/fixed spacers have no action. Lay out actual items ourselves.
            return (item.action != nil || item.customView != nil || hasMenu)
                && seen.insert(ObjectIdentifier(item)).inserted
        }
        titleLabel.text = controller.navigationItem.title ?? controller.title
        let titleHeight = max(28, ceil(titleLabel.font.lineHeight))
        titleHeightConstraint.constant = titleHeight
        dock.isHidden = items.isEmpty
        let usesLargeText = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let itemsPerRow = usesLargeText ? 2 : 3
        let rowCount = (items.count + itemsPerRow - 1) / itemsPerRow
        let rowHeight = CGFloat(max(1, rowCount)) * 48 + CGFloat(max(0, rowCount - 1)) * 4
        let controlHeight = usesLargeText ? rowHeight + titleHeight + 8 : max(rowHeight, titleHeight)
        let height = controlHeight + 16
        let bottomPadding = max(0, view.safeAreaInsets.bottom - keyboardOverlap)
        dockHeightConstraint.constant = height + bottomPadding
        bottomConstraint.constant = -keyboardOverlap
        barBottomConstraint.constant = -8 - bottomPadding
        barLayout.axis = usesLargeText ? .vertical : .horizontal
        barLayout.alignment = usesLargeText ? .trailing : .center
        barLayout.spacing = usesLargeText ? 8 : 12
        rowsHeightConstraint.constant = rowHeight
        // Icon-only actions stay compact; text actions have room for their labels.
        let buttonWidth: CGFloat = items.contains { $0.image == nil } ? 80 : 48
        let columns = max(1, min(items.count, itemsPerRow))
        rowsWidthConstraint.constant = CGFloat(columns) * buttonWidth + CGFloat(columns - 1) * RightHandLayout.spacing

        if displayedItems.map(ObjectIdentifier.init) != items.map(ObjectIdentifier.init)
            || rows.arrangedSubviews.count != rowCount {
            displayedItems = items
            rows.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for start in stride(from: 0, to: items.count, by: itemsPerRow) {
                let row = UIStackView()
                RightHandLayout.align(row)
                row.distribution = .fillEqually
                row.heightAnchor.constraint(equalToConstant: 48).isActive = true
                let group = Array(items[start..<min(start + itemsPerRow, items.count)])
                for item in group {
                    if let customView = item.customView {
                        row.addArrangedSubview(customView)
                    } else {
                        row.addArrangedSubview(ReachableBarButton(item: item))
                    }
                }
                rows.addArrangedSubview(row)
            }
        }
        if insetOwner !== controller {
            insetOwner?.additionalSafeAreaInsets = originalInsets
            insetOwner = controller
            originalInsets = controller.additionalSafeAreaInsets
        }
        var insets = originalInsets
        insets.bottom += (items.isEmpty ? 0 : height) + max(0, keyboardOverlap - view.safeAreaInsets.bottom)
        if controller.additionalSafeAreaInsets != insets {
            controller.additionalSafeAreaInsets = insets
        }
    }

    private func observeItems(of controller: UIViewController) {
        guard observedController !== controller else { return }
        observedController = controller
        itemObservations = [
            controller.navigationItem.observe(\.leftBarButtonItems, options: [.new]) { [weak self] _, _ in self?.scheduleRefresh() },
            controller.navigationItem.observe(\.rightBarButtonItems, options: [.new]) { [weak self] _, _ in self?.scheduleRefresh() },
            controller.navigationItem.observe(\.title, options: [.new]) { [weak self] _, _ in self?.scheduleRefresh() },
            controller.observe(\.toolbarItems, options: [.new]) { [weak self] _, _ in self?.scheduleRefresh() },
        ]
    }

    @objc private func scheduleRefresh() {
        guard !refreshPending else { return }
        refreshPending = true
        DispatchQueue.main.async { [weak self] in
            self?.refreshPending = false
            self?.refreshReachableActions()
        }
    }

    @objc private func goBack() { popViewController(animated: true) }

    @objc private func keyboardFrameChanged(_ notification: Notification) {
        guard RightHandLayout.isEnabled, isViewLoaded, view.window != nil,
              let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardFrame = view.convert(frame, from: nil)
        let intersection = view.bounds.intersection(keyboardFrame)
        keyboardOverlap = intersection.isNull || intersection.maxY < view.bounds.maxY - 1
            ? 0 : max(0, view.bounds.maxY - intersection.minY)
        refreshReachableActions()
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.view.layoutIfNeeded()
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
