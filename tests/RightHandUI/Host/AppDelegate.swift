import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let scenario = ProcessInfo.processInfo.arguments
        let root: UIViewController
        if scenario.contains("library") {
            root = ReachableNavigationController(rootViewController: LibraryScreen())
        } else if scenario.contains("toolbar") {
            root = ToolbarScreen()
        } else {
            root = ReachableNavigationController(rootViewController: FormScreen(isEditor: false))
        }
        if scenario.contains("dark") { window.overrideUserInterfaceStyle = .dark }
        window.rootViewController = root
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

final class ToolbarScreen: UIViewController {
    private let toolbar = BottomToolbar()
    private let addressBar = AddressBar()
    private let result = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        result.text = "Reynard"
        result.font = .preferredFont(forTextStyle: .largeTitle)
        result.textAlignment = .center
        result.accessibilityIdentifier = "result"
        result.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(result)
        view.addSubview(toolbar)
        toolbar.configureTopAnchor(to: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            result.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            result.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        toolbar.attachAddressBar(addressBar)
        toolbar.apply(state: .standard, hidesButtons: false)
        toolbar.updateNavigation(canGoBack: true, canGoForward: true, canShare: true)
        toolbar.onBack = { [weak self] in self?.result.text = "Back" }
        toolbar.onForward = { [weak self] in self?.result.text = "Forward" }
        toolbar.onShare = { [weak self] in self?.result.text = "Share" }
        toolbar.onLibrary = { [weak self] in self?.result.text = "Library" }
        toolbar.onDownloads = { [weak self] in self?.result.text = "Downloads" }
        toolbar.onTabOverview = { [weak self] in self?.result.text = "Tabs" }
    }
}

final class FormScreen: UITableViewController {
    private let isEditor: Bool
    private let field = UITextField()
    private lazy var save = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveForm))
    init(isEditor: Bool) {
        self.isEditor = isEditor
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = isEditor ? "Edit Bookmark" : "Settings"
        tableView.rowHeight = 56
        if isEditor {
            field.placeholder = "Bookmark name"
            field.accessibilityIdentifier = "name"
            field.autocorrectionType = .no
            field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
            save.accessibilityIdentifier = "save"
            save.isEnabled = false
            navigationItem.rightBarButtonItem = save
            let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelForm))
            cancel.accessibilityIdentifier = "cancel"
            navigationItem.leftBarButtonItem = cancel
        } else {
            let next = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(openEditor))
            next.accessibilityIdentifier = "edit"
            navigationItem.rightBarButtonItem = next
            if #available(iOS 14.0, *) {
                let menu = UIBarButtonItem(title: "Sections", menu: UIMenu(children: [
                    UIAction(title: "Downloads") { [weak self] _ in self?.title = "Downloads" }
                ]))
                menu.accessibilityIdentifier = "sections"
                navigationItem.leftBarButtonItem = menu
            }
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { isEditor ? 1 : 12 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        if isEditor {
            field.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(field)
            NSLayoutConstraint.activate([
                field.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                field.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                field.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            ])
        } else {
            cell.textLabel?.text = indexPath.row == 0 ? "Appearance" : "Setting \(indexPath.row + 1)"
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    @objc private func openEditor() { navigationController?.pushViewController(FormScreen(isEditor: true), animated: true) }
    @objc private func fieldChanged() { save.isEnabled = !(field.text ?? "").isEmpty }
    @objc private func saveForm() { view.endEditing(true); title = "Saved" }
    @objc private func cancelForm() { navigationController?.popViewController(animated: true) }
}

// Reproduce the nested tab-controller container used by the library sheet.
final class LibraryScreen: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        let settings = FormScreen(isEditor: false)
        settings.tabBarItem = UITabBarItem(title: "Settings", image: nil, tag: 0)
        setViewControllers([settings], animated: false)
        tabBar.isHidden = true
        if #available(iOS 14.0, *) {
            let sections = UIBarButtonItem(title: "Library", menu: UIMenu(children: [
                UIAction(title: "Settings", state: .on) { _ in }
            ]))
            sections.accessibilityIdentifier = "library.sections"
            navigationItem.leftBarButtonItem = sections
        }
        let close = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain,
                                    target: self, action: #selector(closeLibrary))
        close.accessibilityIdentifier = "library.close"
        close.accessibilityLabel = "Close"
        navigationItem.rightBarButtonItem = close
    }
    @objc private func closeLibrary() { title = "Closed" }
}
