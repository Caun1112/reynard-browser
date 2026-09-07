import UIKit

/// Keeps the original navigation items (including menus and enabled state), but
/// presents them in a bottom dock on iPhone. iPad retains standard navigation.
class ReachableNavigationController: UINavigationController {
    private let dock = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let rows = UIStackView()
    private let titleLabel = UILabel()
    private let readingTitleLabel = UILabel()
    private var readingTitleBottomConstraint: NSLayoutConstraint!
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
        view.addSubview(dock)
        readingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        readingTitleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        readingTitleLabel.adjustsFontForContentSizeCategory = true
        readingTitleLabel.textAlignment = .right
        readingTitleLabel.numberOfLines = 2
        readingTitleLabel.textColor = .label
        readingTitleLabel.isAccessibilityElement = false
        view.addSubview(readingTitleLabel)
        readingTitleBottomConstraint = readingTitleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.textAlignment = .right
        titleLabel.numberOfLines = 1
        titleLabel.accessibilityTraits = .header
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dock.contentView.addSubview(titleLabel)

        rows.axis = .vertical
        rows.spacing = 4
        rows.translatesAutoresizingMaskIntoConstraints = false
        dock.contentView.addSubview(rows)
        bottomConstraint = dock.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        dockHeightConstraint = dock.heightAnchor.constraint(equalToConstant: 84)
        titleHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: 28)
        NSLayoutConstraint.activate([
            readingTitleLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 24),
            readingTitleLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -24),
            readingTitleBottomConstraint,
            dock.leftAnchor.constraint(equalTo: view.leftAnchor),
            dock.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomConstraint,
            dockHeightConstraint,
            titleLabel.topAnchor.constraint(equalTo: dock.contentView.topAnchor, constant: 8),
            titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: dock.contentView.safeAreaLayoutGuide.leftAnchor, constant: 16),
            titleLabel.rightAnchor.constraint(equalTo: dock.contentView.safeAreaLayoutGuide.rightAnchor, constant: -16),
            titleHeightConstraint,
            rows.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            rows.rightAnchor.constraint(equalTo: dock.contentView.safeAreaLayoutGuide.rightAnchor, constant: -RightHandLayout.edgeInset),
            rows.widthAnchor.constraint(equalToConstant: 240).withPriority(.defaultHigh),
            rows.leftAnchor.constraint(greaterThanOrEqualTo: dock.contentView.safeAreaLayoutGuide.leftAnchor, constant: RightHandLayout.edgeInset),
            rows.bottomAnchor.constraint(equalTo: dock.contentView.bottomAnchor, constant: -4),
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
            view.bringSubviewToFront(readingTitleLabel)
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
        readingTitleLabel.text = titleLabel.text
        let titleHeight = max(28, ceil(titleLabel.font.lineHeight))
        titleHeightConstraint.constant = titleHeight
        dock.isHidden = items.isEmpty
        let itemsPerRow = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 3
        let rowCount = (items.count + itemsPerRow - 1) / itemsPerRow
        let height = items.isEmpty ? 0 : CGFloat(rowCount) * 52 + titleHeight + 12
        dockHeightConstraint.constant = height

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
        insets.bottom += height + keyboardOverlap
        // A reading header lets the first form/list row start within thumb reach.
        // The full height becomes available while typing and in landscape.
        let readingSpace: CGFloat = height > 0 && view.bounds.height > 600 && keyboardOverlap == 0
            ? min(340, max(0, (view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - height) * 0.45)) : 0
        insets.top += readingSpace
        readingTitleLabel.isHidden = readingSpace < 100
        readingTitleBottomConstraint.constant = readingSpace - 24
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
            ? 0 : max(0, view.bounds.maxY - intersection.minY - view.safeAreaInsets.bottom)
        bottomConstraint.constant = -keyboardOverlap
        refreshReachableActions()
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 7
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.view.layoutIfNeeded()
        }
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
