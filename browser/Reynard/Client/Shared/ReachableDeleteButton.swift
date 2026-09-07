import UIKit

/// Editing keeps reorder handles and deletion together at the physical right edge.
/// Keep the usual two-step delete interaction to avoid accidental taps while moving rows.
final class ReachableDeleteButton: UIButton {
    private let onDelete: () -> Void

    init(onDelete: @escaping () -> Void) {
        self.onDelete = onDelete
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        tintColor = .systemRed
        setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        accessibilityLabel = NSLocalizedString("Delete", comment: "")
        addTarget(self, action: #selector(confirmDelete), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func confirmDelete() {
        AlertPresenter.show(title: NSLocalizedString("Delete", comment: ""), message: nil, buttons: [
            .init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel),
            .init(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: onDelete),
        ])
    }
}
