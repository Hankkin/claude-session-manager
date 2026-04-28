import AppKit

class SelectionBarView: NSView {

    var onDelete: (() -> Void)?
    var onCancel: (() -> Void)?

    private let countLabel = NSTextField(labelWithString: "")
    private let deleteButton = SecondaryButton(title: "Delete", style: .destructive)
    private let cancelButton = SecondaryButton(title: "Cancel", style: .neutral)

    var selectionCount: Int = 0 {
        didSet { updateContent() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = Layout.cornerRadiusLarge
        layer?.backgroundColor = NSColor.themeAdaptiveSecondaryBackground.cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.1
        layer?.shadowOffset = CGSize(width: 0, height: -2)
        layer?.shadowRadius = 8

        translatesAutoresizingMaskIntoConstraints = false

        // Count label with checkmark
        let checkmark = NSImageView()
        checkmark.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
        checkmark.contentTintColor = NSColor.themeAdaptiveAccent
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkmark)

        countLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        countLabel.textColor = NSColor.themeTextPrimary
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        // Buttons
        deleteButton.target = self
        deleteButton.action = #selector(deleteClicked)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(deleteButton)

        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cancelButton)

        NSLayoutConstraint.activate([
            checkmark.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.lg),
            checkmark.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 18),
            checkmark.heightAnchor.constraint(equalToConstant: 18),

            countLabel.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: Spacing.sm),
            countLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.md),
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),

            deleteButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -Spacing.sm),
            deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            deleteButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            heightAnchor.constraint(equalToConstant: 48)
        ])

        updateContent()
    }

    private func updateContent() {
        countLabel.stringValue = "\(selectionCount) session\(selectionCount == 1 ? "" : "s") selected"
        deleteButton.isEnabled = selectionCount > 0
    }

    func updateSelection(count: Int) {
        selectionCount = count
    }

    @objc private func deleteClicked() {
        onDelete?()
    }

    @objc private func cancelClicked() {
        onCancel?()
    }

    // MARK: - Animation

    func show(animated: Bool = true) {
        if animated {
            alphaValue = 0
            isHidden = false
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.allowsImplicitAnimation = true
                alphaValue = 1
                frame.origin.y = superview?.bounds.height ?? 0
            }
        } else {
            isHidden = false
            alphaValue = 1
        }
    }

    func hide(animated: Bool = true) {
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.allowsImplicitAnimation = true
                alphaValue = 0
            }) {
                self.isHidden = true
            }
        } else {
            isHidden = true
        }
    }
}
