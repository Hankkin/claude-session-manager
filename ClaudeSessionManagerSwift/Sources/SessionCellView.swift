import AppKit

class SessionCellView: NSTableCellView {

    private let projectLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let previewLabel = NSTextField(labelWithString: "")
    private let countLabel = NSTextField(labelWithString: "")
    private let checkBox = NSButton()
    private let separator = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        wantsLayer = true

        // Check box (hidden by default)
        checkBox.bezelStyle = .regularSquare
        checkBox.setButtonType(.switch)
        checkBox.title = ""
        checkBox.isHidden = true
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkBox)

        // Project label (top-left)
        projectLabel.font = .systemFont(ofSize: 11, weight: .medium)
        projectLabel.textColor = .tertiaryLabelColor
        projectLabel.lineBreakMode = .byTruncatingTail
        projectLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(projectLabel)

        // Time label (top-right)
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .tertiaryLabelColor
        timeLabel.alignment = .right
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)

        // Preview label (main content)
        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = .labelColor
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.maximumNumberOfLines = 2
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewLabel)

        // Count label (bottom-right)
        countLabel.font = .systemFont(ofSize: 11)
        countLabel.textColor = .quaternaryLabelColor
        countLabel.alignment = .right
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        // Bottom separator
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        NSLayoutConstraint.activate([
            checkBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            checkBox.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 18),

            projectLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            projectLabel.leadingAnchor.constraint(equalTo: checkBox.trailingAnchor, constant: 6),
            projectLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            timeLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 120),

            previewLabel.topAnchor.constraint(equalTo: projectLabel.bottomAnchor, constant: 3),
            previewLabel.leadingAnchor.constraint(equalTo: checkBox.trailingAnchor, constant: 6),
            previewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            countLabel.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 2),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            countLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with session: Session, isSelectMode: Bool, isSelected: Bool) {
        projectLabel.stringValue = session.shortProject
        timeLabel.stringValue = session.formattedTime
        previewLabel.stringValue = session.truncatedMessage
        countLabel.stringValue = "\(session.messageCount) 条消息"

        checkBox.isHidden = !isSelectMode
        checkBox.state = isSelected ? .on : .off

        // Adjust leading constraint based on select mode
        if isSelectMode {
            checkBox.isHidden = false
        } else {
            checkBox.isHidden = true
        }
    }
}
