import AppKit

class EmptyStateView: NSView {

    enum State {
        case noSessions
        case noSearchResults
        case loading
    }

    var state: State = .noSessions {
        didSet { updateContent() }
    }

    private let iconImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")

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

        // Icon
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentTintColor = NSColor.themeTextTertiary
        addSubview(iconImageView)

        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = NSColor.themeTextPrimary
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Subtitle
        subtitleLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = NSColor.themeTextSecondary
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -24)
        ])

        updateContent()
    }

    private func updateContent() {
        switch state {
        case .noSessions:
            iconImageView.image = NSImage(systemSymbolName: "bubble.left.and.bubble.right", accessibilityDescription: nil)
            titleLabel.stringValue = "暂无会话"
            subtitleLabel.stringValue = "使用 Claude Code 开始新对话\n会话将显示在这里。"

        case .noSearchResults:
            iconImageView.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            titleLabel.stringValue = "没有找到匹配的会话"
            subtitleLabel.stringValue = "尝试其他搜索词。"

        case .loading:
            iconImageView.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
            titleLabel.stringValue = "加载中..."
            subtitleLabel.stringValue = ""
        }
    }
}
