import AppKit

class SessionRowView: NSView {

    private var session: Session?
    private var isSelectMode = false
    private var isRowSelected = false

    private let containerView = NSView()
    private let selectionIndicator = NSView()
    private let projectLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let previewLabel = NSTextField(labelWithString: "")
    private let countLabel = NSTextField(labelWithString: "")
    private let checkboxButton = NSButton()
    private let weclaudeIcon = NSImageView()
    private let pinIcon = NSImageView()
    private let bottomBorder = NSView()

    private var trackingArea: NSTrackingArea?
    private var isMouseOver = false {
        didSet { updateAppearance() }
    }

    // Leading constraint outlets for select mode adjustment
    private var projectLabelLeadingConstraint: NSLayoutConstraint!
    private var previewLabelLeadingConstraint: NSLayoutConstraint!
    private var countLabelLeadingConstraint: NSLayoutConstraint!

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

        // Selection indicator (left accent bar) - 3pt for stronger visibility
        selectionIndicator.wantsLayer = true
        selectionIndicator.layer?.backgroundColor = NSColor.themeAdaptiveAccent.cgColor
        selectionIndicator.isHidden = true
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionIndicator)

        // Checkbox for select mode
        checkboxButton.bezelStyle = .regularSquare
        checkboxButton.setButtonType(.switch)
        checkboxButton.title = ""
        checkboxButton.isHidden = true
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkboxButton)

        // Project label (top) - larger, more prominent
        projectLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        projectLabel.textColor = NSColor.themeTextPrimary
        projectLabel.lineBreakMode = .byTruncatingTail
        projectLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(projectLabel)

        // Time label (top right)
        timeLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = NSColor.themeTextTertiary
        timeLabel.alignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)

        // Preview label (middle, 2 lines max) - clearer text
        previewLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        previewLabel.textColor = NSColor.themeTextSecondary
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.maximumNumberOfLines = 2
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewLabel)

        // Count label (bottom)
        countLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        countLabel.textColor = NSColor.themeTextTertiary
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        // Pin icon - more visible
        pinIcon.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pinned")
        pinIcon.contentTintColor = NSColor.themeAccent
        pinIcon.isHidden = true
        pinIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pinIcon)

        // WeCLaude icon - small WeChat icon
        weclaudeIcon.image = NSImage(systemSymbolName: "message.fill", accessibilityDescription: "WeCLaude")
        weclaudeIcon.contentTintColor = NSColor.systemGreen
        weclaudeIcon.isHidden = true
        weclaudeIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(weclaudeIcon)

        // Bottom border - subtle divider
        bottomBorder.wantsLayer = true
        bottomBorder.layer?.backgroundColor = NSColor.themeAdaptiveBorder.withAlphaComponent(0.5).cgColor
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBorder)

        setupConstraints()
    }

    private func setupConstraints() {
        // Project label leading constraint
        projectLabelLeadingConstraint = projectLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        // Preview label leading constraint
        previewLabelLeadingConstraint = previewLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        // Count label leading constraint
        countLabelLeadingConstraint = countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)

        NSLayoutConstraint.activate([
            // Selection indicator
            selectionIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionIndicator.topAnchor.constraint(equalTo: topAnchor),
            selectionIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 2),

            // Checkbox
            checkboxButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            checkboxButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 18),

            // Project label
            projectLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            projectLabelLeadingConstraint,
            projectLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

            // Time label
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 100),

            // Preview label
            previewLabel.topAnchor.constraint(equalTo: projectLabel.bottomAnchor, constant: 4),
            previewLabelLeadingConstraint,
            previewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            // Count label
            countLabel.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 4),
            countLabelLeadingConstraint,
            countLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),

            // Pin icon
            pinIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            pinIcon.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 12),
            pinIcon.heightAnchor.constraint(equalToConstant: 12),

            // WeCLaude icon - small icon between project and time
            weclaudeIcon.leadingAnchor.constraint(equalTo: projectLabel.trailingAnchor, constant: 6),
            weclaudeIcon.centerYAnchor.constraint(equalTo: projectLabel.centerYAnchor),
            weclaudeIcon.widthAnchor.constraint(equalToConstant: 14),
            weclaudeIcon.heightAnchor.constraint(equalToConstant: 14),

            // Bottom border
            bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with session: Session, isSelectMode: Bool, isSelected: Bool) {
        self.session = session
        self.isSelectMode = isSelectMode
        self.isRowSelected = isSelected

        projectLabel.stringValue = session.shortProject
        timeLabel.stringValue = session.formattedTime
        previewLabel.stringValue = session.truncatedMessage
        countLabel.stringValue = "\(session.messageCount) messages"

        checkboxButton.state = isSelected ? .on : .off
        checkboxButton.isHidden = !isSelectMode
        pinIcon.isHidden = !session.isPinned

        // Show WeCLaude icon for WeCLaude sessions
        weclaudeIcon.isHidden = !session.isWeCLaudeSession

        // Adjust leading constraints for select mode (make room for checkbox)
        let leadingConstant: CGFloat = isSelectMode ? 40 : 16
        projectLabelLeadingConstraint?.constant = leadingConstant
        previewLabelLeadingConstraint?.constant = leadingConstant
        countLabelLeadingConstraint?.constant = leadingConstant

        // Force layout update
        needsLayout = true
        layoutSubtreeIfNeeded()

        updateAppearance()
    }

    private func updateAppearance() {
        // Selection indicator
        selectionIndicator.isHidden = !isRowSelected

        // Background
        if isRowSelected {
            layer?.backgroundColor = NSColor.themeAdaptiveSelectedBackground.cgColor
        } else if isMouseOver {
            layer?.backgroundColor = NSColor.themeAdaptiveTertiaryBackground.cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isMouseOver = true
    }

    override func mouseExited(with event: NSEvent) {
        isMouseOver = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        session = nil
        isSelectMode = false
        isRowSelected = false
        isMouseOver = false
        checkboxButton.isHidden = true
        selectionIndicator.isHidden = true
        weclaudeIcon.isHidden = true
        pinIcon.isHidden = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}
