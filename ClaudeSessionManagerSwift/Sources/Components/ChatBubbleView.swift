import AppKit

struct ParsedMessage {
    enum Role {
        case user
        case assistant
    }
    let role: Role
    let content: String
}

// WeChat-style chat bubble view
class WeChatBubbleView: NSView {

    private let bubbleContainer = NSView()
    private let contentLabel = NSTextField(labelWithString: "")

    private var isUserMessage = false
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    // WeChat colors
    private let wechatGreen = NSColor(red: 7/255, green: 193/255, blue: 96/255, alpha: 1.0)  // #07C160
    private let wechatWhite = NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)

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

        // Bubble container with rounded corners
        bubbleContainer.wantsLayer = true
        bubbleContainer.layer?.cornerRadius = 12
        bubbleContainer.layer?.masksToBounds = true
        bubbleContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bubbleContainer)

        // Content label - uses intrinsic size for height
        contentLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        contentLabel.textColor = .black
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.maximumNumberOfLines = 0
        contentLabel.isEditable = false
        contentLabel.isSelectable = true
        contentLabel.isBordered = false
        contentLabel.backgroundColor = .clear
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleContainer.addSubview(contentLabel)

        // Initial constraints
        leadingConstraint = bubbleContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        trailingConstraint = bubbleContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)

        NSLayoutConstraint.activate([
            contentLabel.topAnchor.constraint(equalTo: bubbleContainer.topAnchor, constant: 10),
            contentLabel.bottomAnchor.constraint(equalTo: bubbleContainer.bottomAnchor, constant: -10),
            contentLabel.leadingAnchor.constraint(equalTo: bubbleContainer.leadingAnchor, constant: 14),
            contentLabel.trailingAnchor.constraint(equalTo: bubbleContainer.trailingAnchor, constant: -14),
            contentLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 400),

            bubbleContainer.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            bubbleContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            leadingConstraint,
            trailingConstraint
        ])
    }

    func configure(isUser: Bool, content: String) {
        self.isUserMessage = isUser
        contentLabel.stringValue = content

        if isUser {
            // User message - WeChat green on right
            bubbleContainer.layer?.backgroundColor = wechatGreen.cgColor
            contentLabel.textColor = .white

            // Position bubble on right side
            leadingConstraint.isActive = false
            trailingConstraint.constant = -16
            trailingConstraint.isActive = true
        } else {
            // Assistant message - white on left
            bubbleContainer.layer?.backgroundColor = wechatWhite.cgColor
            contentLabel.textColor = .black

            // Position bubble on left side
            trailingConstraint.isActive = false
            leadingConstraint.constant = 16
            leadingConstraint.isActive = true
        }

        // Force layout update to recalculate intrinsic size
        invalidateIntrinsicContentSize()
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    override var fittingSize: NSSize {
        // Calculate based on label's fitting size plus padding
        let labelWidth: CGFloat = min(contentLabel.fittingSize.width, 400)
        let labelHeight = contentLabel.fittingSize.height
        return NSSize(width: labelWidth + 28, height: labelHeight + 20)
    }

    override var intrinsicContentSize: NSSize {
        return fittingSize
    }
}

// Chat content view with WeChat-style bubbles
class ChatContentView: NSView {

    private var bubbleViews: [WeChatBubbleView] = []
    private var contentHeightConstraint: NSLayoutConstraint!

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
        // Create height constraint for this view
        contentHeightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
        contentHeightConstraint.priority = .defaultHigh
        contentHeightConstraint.isActive = true
    }

    override var intrinsicContentSize: NSSize {
        let height = bubbleViews.reduce(0) { max($0, $1.fittingSize.height + 8) } + 16
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    func configure(with content: String) {
        // Remove existing bubbles
        for bubble in bubbleViews {
            bubble.removeFromSuperview()
        }
        bubbleViews.removeAll()

        let messages = parseMessages(content)

        if messages.isEmpty {
            contentHeightConstraint.constant = 100
            return
        }

        var yOffset: CGFloat = 8

        for message in messages {
            let bubble = WeChatBubbleView()
            bubble.configure(isUser: message.role == .user, content: message.content)
            bubble.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bubble)

            // Let bubble determine its own height via intrinsic size
            NSLayoutConstraint.activate([
                bubble.topAnchor.constraint(equalTo: topAnchor, constant: yOffset),
                bubble.leadingAnchor.constraint(equalTo: leadingAnchor),
                bubble.trailingAnchor.constraint(equalTo: trailingAnchor),
                // Remove fixed height constraint - let intrinsic size handle it
            ])

            // Get actual height after layout
            bubble.layoutSubtreeIfNeeded()
            let bubbleHeight = bubble.fittingSize.height
            yOffset += bubbleHeight + 8
            bubbleViews.append(bubble)
        }

        contentHeightConstraint.constant = yOffset + 8
        invalidateIntrinsicContentSize()
    }

    func appendContent(_ content: String) {
        let newMessages = parseMessages(content)

        if newMessages.isEmpty {
            return
        }

        // Calculate starting Y offset from last bubble
        var yOffset: CGFloat = 8
        for bubble in bubbleViews {
            bubble.layoutSubtreeIfNeeded()
            yOffset += bubble.fittingSize.height + 8
        }

        for message in newMessages {
            let bubble = WeChatBubbleView()
            bubble.configure(isUser: message.role == .user, content: message.content)
            bubble.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bubble)

            NSLayoutConstraint.activate([
                bubble.topAnchor.constraint(equalTo: topAnchor, constant: yOffset),
                bubble.leadingAnchor.constraint(equalTo: leadingAnchor),
                bubble.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])

            bubble.layoutSubtreeIfNeeded()
            let bubbleHeight = bubble.fittingSize.height
            yOffset += bubbleHeight + 8
            bubbleViews.append(bubble)
        }

        contentHeightConstraint.constant = yOffset + 8
        invalidateIntrinsicContentSize()
    }

    private func parseMessages(_ content: String) -> [ParsedMessage] {
        var messages: [ParsedMessage] = []
        let blocks = content.components(separatedBy: "\n\n")

        for block in blocks {
            let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("[用户") {
                let text = trimmed.replacingOccurrences(of: "^\\[用户 \\d+\\]\\n?", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty && !text.hasPrefix("...") {
                    messages.append(ParsedMessage(role: .user, content: text))
                }
            } else if trimmed.hasPrefix("[助手") {
                let text = trimmed.replacingOccurrences(of: "^\\[助手 \\d+\\]\\n?", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty && !text.hasPrefix("...") {
                    messages.append(ParsedMessage(role: .assistant, content: text))
                }
            } else if !trimmed.hasPrefix("...") {
                messages.append(ParsedMessage(role: .assistant, content: trimmed))
            }
        }

        return messages
    }
}