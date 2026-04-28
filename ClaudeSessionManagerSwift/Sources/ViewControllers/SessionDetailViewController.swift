import AppKit

protocol SessionDetailViewControllerDelegate: AnyObject {
    func detailDidRequestResume(_ session: Session)
    func detailDidRequestCopyId(_ sessionId: String)
    func detailDidRequestDelete(_ session: Session)
    func detailDidTogglePin(_ session: Session)
}

class SessionDetailViewController: NSViewController {

    weak var delegate: SessionDetailViewControllerDelegate?

    private var currentSession: Session?
    private var sessionManager: SessionManager?
    private var currentLoadOffset: Int = 20
    private var isLoadingMore: Bool = false
    private var hasMoreContent: Bool = true

    private let containerView = NSView()
    private let emptyLabel = NSTextField(labelWithString: "选择一个会话查看详情")
    private let projectLabel = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let idLabel = NSTextField(labelWithString: "")
    private let countLabel = NSTextField(labelWithString: "")
    private let dateLabel = NSTextField(labelWithString: "")
    private let resumeButton = PrimaryButton(title: "Resume Session")
    private let pinButton = NSButton(title: "📌 Pin", target: nil, action: nil)
    private let copyButton = SecondaryButton(title: "Copy ID")
    private let deleteButton = SecondaryButton(title: "Delete", style: .destructive)
    private let contentScrollView = AutoLoadScrollView()
    private let chatContentView = ChatContentView()
    private let divider1 = Divider()
    private let divider2 = Divider()
    private let divider3 = Divider()
    private let loadingIndicator = NSProgressIndicator()

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        showEmptyState()
    }

    private func setupViews() {
        // Container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Empty state label
        emptyLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        emptyLabel.textColor = NSColor.themeTextSecondary
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)

        // Project label - larger and more prominent
        projectLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        projectLabel.textColor = NSColor.themeTextPrimary
        projectLabel.lineBreakMode = .byTruncatingMiddle
        projectLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(projectLabel)

        // Time label
        timeLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = NSColor.themeTextSecondary
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeLabel)

        // ID label (monospace) - less prominent, secondary info
        idLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        idLabel.textColor = NSColor.themeTextTertiary
        idLabel.lineBreakMode = .byTruncatingTail
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(idLabel)

        // Count label
        countLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        countLabel.textColor = NSColor.themeTextSecondary
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(countLabel)

        // Date label
        dateLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        dateLabel.textColor = NSColor.themeTextTertiary
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dateLabel)

        // Dividers
        divider1.translatesAutoresizingMaskIntoConstraints = false
        divider2.translatesAutoresizingMaskIntoConstraints = false
        divider3.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(divider1)
        containerView.addSubview(divider2)
        containerView.addSubview(divider3)

        // Resume button
        resumeButton.target = self
        resumeButton.action = #selector(resumeClicked)
        resumeButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(resumeButton)

        // Pin button
        pinButton.target = self
        pinButton.action = #selector(pinClicked)
        pinButton.bezelStyle = .rounded
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(pinButton)

        // Copy button
        copyButton.target = self
        copyButton.action = #selector(copyClicked)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(copyButton)

        // Delete button
        deleteButton.target = self
        deleteButton.action = #selector(deleteClicked)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(deleteButton)

        // Loading indicator (for auto-load)
        loadingIndicator.style = .spinning
        loadingIndicator.controlSize = .small
        loadingIndicator.isHidden = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(loadingIndicator)

        // Content scroll view
        contentScrollView.hasVerticalScroller = true
        contentScrollView.autohidesScrollers = true
        contentScrollView.drawsBackground = false
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentScrollView)

        // Chat content view
        chatContentView.translatesAutoresizingMaskIntoConstraints = false
        chatContentView.frame = NSRect(x: 0, y: 0, width: contentScrollView.contentSize.width, height: 400)
        contentScrollView.documentView = chatContentView

        // Set up constraints for chat content view within scroll view
        chatContentView.leadingAnchor.constraint(equalTo: contentScrollView.contentView.leadingAnchor).isActive = true
        chatContentView.trailingAnchor.constraint(equalTo: contentScrollView.contentView.trailingAnchor).isActive = true
        chatContentView.topAnchor.constraint(equalTo: contentScrollView.contentView.topAnchor).isActive = true
        chatContentView.widthAnchor.constraint(equalTo: contentScrollView.contentView.widthAnchor).isActive = true

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container fills view
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty label
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Project label
            projectLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            projectLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            projectLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -12),

            // Time label
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // ID label
            idLabel.topAnchor.constraint(equalTo: projectLabel.bottomAnchor, constant: 8),
            idLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),

            // Count label
            countLabel.topAnchor.constraint(equalTo: projectLabel.bottomAnchor, constant: 8),
            countLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Date label (below count)
            dateLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Divider 1
            divider1.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            divider1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            divider1.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Resume button
            resumeButton.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 16),
            resumeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            resumeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            resumeButton.heightAnchor.constraint(equalToConstant: 44),

            // Pin button
            pinButton.topAnchor.constraint(equalTo: resumeButton.bottomAnchor, constant: 12),
            pinButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            pinButton.heightAnchor.constraint(equalToConstant: 32),
            pinButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),

            // Copy & Delete buttons
            copyButton.centerYAnchor.constraint(equalTo: pinButton.centerYAnchor),
            copyButton.leadingAnchor.constraint(equalTo: pinButton.trailingAnchor, constant: 8),
            copyButton.heightAnchor.constraint(equalToConstant: 32),

            deleteButton.centerYAnchor.constraint(equalTo: pinButton.centerYAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: copyButton.trailingAnchor, constant: 8),
            deleteButton.heightAnchor.constraint(equalToConstant: 32),

            // Divider 2
            divider2.topAnchor.constraint(equalTo: pinButton.bottomAnchor, constant: 16),
            divider2.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            divider2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            // Loading indicator (centered below divider2)
            loadingIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 12),

            // Content scroll view
            contentScrollView.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 8),
            contentScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func showEmptyState() {
        containerView.isHidden = true
        emptyLabel.isHidden = false
    }

    private func showSessionContent() {
        containerView.isHidden = false
        emptyLabel.isHidden = true
    }

    func configure(with session: Session, manager: SessionManager) {
        self.currentSession = session
        self.sessionManager = manager

        projectLabel.stringValue = session.shortProject
        timeLabel.stringValue = session.formattedTime
        idLabel.stringValue = session.id
        countLabel.stringValue = "\(session.messageCount) messages"
        dateLabel.stringValue = session.formattedDate

        // Update pin button
        pinButton.title = session.isPinned ? "📌 Unpin" : "📌 Pin"

        showSessionContent()

        // Load content asynchronously - just load initial batch
        currentLoadOffset = 20
        isLoadingMore = false
        hasMoreContent = true

        // Set up auto-load callback
        contentScrollView.onScrollNearBottom = { [weak self] in
            self?.loadMoreContent()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let content = manager.loadSessionContent(session: session, maxLines: 20, offset: 0)
            DispatchQueue.main.async {
                guard let self = self, self.currentSession?.id == session.id else { return }
                self.chatContentView.configure(with: content)
                // Determine if there's more content
                let hasMore = !content.contains("会话内容为空")
                self.hasMoreContent = hasMore
                // Scroll to top after loading initial content
                self.contentScrollView.contentView.scroll(to: NSPoint(x: 0, y: 0))
            }
        }
    }

    func clear() {
        currentSession = nil
        showEmptyState()
    }

    func getCurrentSessionId() -> String? {
        return currentSession?.id
    }

    private func loadMoreContent() {
        guard let session = currentSession, let manager = sessionManager, !isLoadingMore, hasMoreContent else { return }

        isLoadingMore = true
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimation(nil)

        let offset = currentLoadOffset
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let content = manager.loadSessionContent(session: session, maxLines: 20, offset: offset)
            DispatchQueue.main.async {
                guard let self = self, self.currentSession?.id == session.id else { return }

                self.chatContentView.appendContent(content)
                self.currentLoadOffset += 20
                self.isLoadingMore = false
                self.loadingIndicator.stopAnimation(nil)
                self.loadingIndicator.isHidden = true

                // Check if there's more content
                let hasMore = !content.contains("会话内容为空") && !content.isEmpty
                self.hasMoreContent = hasMore
            }
        }
    }

    @objc private func resumeClicked() {
        guard let session = currentSession else { return }
        delegate?.detailDidRequestResume(session)
    }

    @objc private func pinClicked() {
        guard let session = currentSession else { return }
        delegate?.detailDidTogglePin(session)
    }

    @objc private func copyClicked() {
        guard let session = currentSession else { return }
        delegate?.detailDidRequestCopyId(session.id)
    }

    @objc private func deleteClicked() {
        guard let session = currentSession else { return }
        delegate?.detailDidRequestDelete(session)
    }
}
