import AppKit

class SessionDetailView: NSView {

    private let session: Session
    private let manager: SessionManager

    private let headerView = NSView()
    private let projectLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let idLabel = NSTextField(labelWithString: "")
    private let countLabel = NSTextField(labelWithString: "")
    private let resumeButton = NSButton()
    private let copyIdButton = NSButton()
    private let deleteButton = NSButton()
    private let contentScrollView = NSScrollView()
    private let contentTextView = NSTextView()
    private let divider = NSView()

    var onDelete: (() -> Void)?
    var onResume: (() -> Void)?

    init(frame: NSRect, session: Session, manager: SessionManager) {
        self.session = session
        self.manager = manager
        super.init(frame: frame)
        setupViews()
        loadContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func setupViews() {
        wantsLayer = true

        // Header
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)

        // Divider
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(divider)

        // Project label
        projectLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        projectLabel.textColor = .labelColor
        projectLabel.lineBreakMode = .byTruncatingMiddle
        projectLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(projectLabel)

        // Time label
        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabelColor
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(timeLabel)

        // ID label
        idLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        idLabel.textColor = .tertiaryLabelColor
        idLabel.lineBreakMode = .byTruncatingTail
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(idLabel)

        // Count label
        countLabel.font = .systemFont(ofSize: 11)
        countLabel.textColor = .tertiaryLabelColor
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(countLabel)

        // Resume button
        resumeButton.title = "▶ 恢复会话"
        resumeButton.bezelStyle = .rounded
        resumeButton.font = .systemFont(ofSize: 12, weight: .medium)
        resumeButton.target = self
        resumeButton.action = #selector(resumeClicked)
        resumeButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(macOS 10.14, *) {
            resumeButton.contentTintColor = .systemBlue
        }
        headerView.addSubview(resumeButton)

        // Copy ID button
        copyIdButton.title = "复制 ID"
        copyIdButton.bezelStyle = .rounded
        copyIdButton.font = .systemFont(ofSize: 12)
        copyIdButton.target = self
        copyIdButton.action = #selector(copyIdClicked)
        copyIdButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(copyIdButton)

        // Delete button
        deleteButton.title = "删除"
        deleteButton.bezelStyle = .rounded
        deleteButton.font = .systemFont(ofSize: 12)
        deleteButton.target = self
        deleteButton.action = #selector(deleteClicked)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(macOS 10.14, *) {
            deleteButton.contentTintColor = .systemRed
        }
        headerView.addSubview(deleteButton)

        // Content scroll view
        contentScrollView.hasVerticalScroller = true
        contentScrollView.autohidesScrollers = true
        contentScrollView.drawsBackground = false
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentScrollView)

        // Content text view
        contentTextView.isEditable = false
        contentTextView.isSelectable = true
        contentTextView.backgroundColor = .clear
        contentTextView.textContainerInset = NSSize(width: 16, height: 16)
        contentTextView.font = .systemFont(ofSize: 13)
        contentTextView.textColor = .labelColor
        if let container = contentTextView.textContainer {
            container.widthTracksTextView = true
        }
        contentScrollView.documentView = contentTextView

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            projectLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            projectLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            projectLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),

            timeLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            timeLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 140),

            idLabel.topAnchor.constraint(equalTo: projectLabel.bottomAnchor, constant: 4),
            idLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            idLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -100),

            countLabel.topAnchor.constraint(equalTo: projectLabel.bottomAnchor, constant: 4),
            countLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            resumeButton.topAnchor.constraint(equalTo: idLabel.bottomAnchor, constant: 12),
            resumeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            resumeButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),

            copyIdButton.centerYAnchor.constraint(equalTo: resumeButton.centerYAnchor),
            copyIdButton.leadingAnchor.constraint(equalTo: resumeButton.trailingAnchor, constant: 8),

            deleteButton.centerYAnchor.constraint(equalTo: resumeButton.centerYAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: copyIdButton.trailingAnchor, constant: 8),

            divider.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            contentScrollView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Populate data
        projectLabel.stringValue = session.shortProject
        timeLabel.stringValue = session.formattedTime
        idLabel.stringValue = session.id
        countLabel.stringValue = "\(session.messageCount) 条消息"
    }

    private func loadContent() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let content = self.manager.loadSessionContent(session: self.session, maxLines: 30)
            DispatchQueue.main.async {
                self.contentTextView.string = content
            }
        }
    }

    @objc private func resumeClicked() {
        onResume?()
    }

    @objc private func copyIdClicked() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(session.id, forType: .string)
    }

    @objc private func deleteClicked() {
        onDelete?()
    }
}
