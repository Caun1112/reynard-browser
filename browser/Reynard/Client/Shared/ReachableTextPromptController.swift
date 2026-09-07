import UIKit

/// Text and authentication prompts use the same reachable actions as other forms.
final class ReachableTextPromptController: UITableViewController, UITextFieldDelegate {
    private let message: String?
    private let fields: [UITextField]
    private let validate: ([String]) -> Bool
    private var completion: (([String]?) -> Void)?
    private var result: [String]?
    private var hasFocusedField = false
    private lazy var confirmItem = UIBarButtonItem(title: confirmTitle, style: .done, target: self, action: #selector(confirm))
    private let confirmTitle: String

    static func present(
        from presenter: UIViewController,
        title: String?,
        message: String? = nil,
        confirmTitle: String = NSLocalizedString("OK", comment: ""),
        fields: [(UITextField) -> Void],
        validate: @escaping ([String]) -> Bool = { _ in true },
        completion: @escaping ([String]?) -> Void
    ) {
        let controller = ReachableTextPromptController(title: title, message: message, confirmTitle: confirmTitle, fields: fields, validate: validate, completion: completion)
        let navigation = ContentModalNavigationController(rootViewController: controller) { [weak controller] in
            controller?.complete()
        }
        navigation.modalPresentationStyle = .formSheet
        presenter.present(navigation, animated: true)
    }

    private init(title: String?, message: String?, confirmTitle: String, fields: [(UITextField) -> Void], validate: @escaping ([String]) -> Bool, completion: @escaping ([String]?) -> Void) {
        self.message = message
        self.confirmTitle = confirmTitle
        self.validate = validate
        self.completion = completion
        self.fields = fields.map { configure in
            let field = UITextField()
            field.font = .preferredFont(forTextStyle: .body)
            field.adjustsFontForContentSizeCategory = true
            configure(field)
            field.accessibilityLabel = field.placeholder ?? title
            return field
        }
        super.init(style: .insetGrouped)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem.reachableSystemItem(.cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = confirmItem
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = max(56, UIFont.preferredFont(forTextStyle: .body).lineHeight + 24)
        for (index, field) in fields.enumerated() {
            field.delegate = self
            field.returnKeyType = index == fields.count - 1 ? .done : .next
            field.addTarget(self, action: #selector(updateValidation), for: .editingChanged)
        }
        updateValidation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasFocusedField else { return }
        hasFocusedField = true
        fields.first?.becomeFirstResponder()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { fields.count }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { message }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        let field = fields[indexPath.row]
        field.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            field.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
        ])
        return cell
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let index = fields.firstIndex(of: textField) else { return false }
        if index + 1 < fields.count { fields[index + 1].becomeFirstResponder() } else { confirm() }
        return false
    }

    private var values: [String] { fields.map { $0.text ?? "" } }

    @objc private func updateValidation() { confirmItem.isEnabled = validate(values) }

    @objc private func confirm() {
        guard validate(values) else { return }
        result = values
        view.endEditing(true)
        navigationController?.dismiss(animated: true)
    }

    @objc private func cancel() {
        result = nil
        view.endEditing(true)
        navigationController?.dismiss(animated: true)
    }

    private func complete() {
        let handler = completion
        completion = nil
        handler?(result)
    }
}
