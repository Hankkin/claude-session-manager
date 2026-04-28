import AppKit

class SecondaryButton: NSButton {

    enum Style {
        case neutral
        case destructive
    }

    var buttonStyle: Style = .neutral {
        didSet { updateAppearance() }
    }

    private var hoverTrackingArea: NSTrackingArea?
    private var isMouseOver = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    convenience init(title: String, style: Style = .neutral) {
        self.init(frame: .zero)
        self.title = title
        self.buttonStyle = style
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 6  // Layout.cornerRadiusSmall
        layer?.borderWidth = 1

        font = NSFont.systemFont(ofSize: 12, weight: .medium)
        bezelStyle = .inline
        isBordered = false
        updateAppearance()
    }

    private func updateAppearance() {
        guard let layer = layer else { return }

        switch buttonStyle {
        case .neutral:
            layer.backgroundColor = NSColor.clear.cgColor
            layer.borderColor = NSColor.themeAdaptiveBorder.cgColor
            // Use title with text color attribute
            let neutralColor = NSColor.themeTextPrimary ?? NSColor.labelColor
            let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: neutralColor]
            attributedTitle = NSAttributedString(string: title, attributes: attrs)
        case .destructive:
            layer.backgroundColor = NSColor.clear.cgColor
            layer.borderColor = NSColor.themeAdaptiveDestructive.cgColor
            // Use red color for destructive
            let destructiveColor = NSColor(red: 1, green: 0.23, blue: 0.19, alpha: 1)  // #FF3B30
            let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: destructiveColor]
            attributedTitle = NSAttributedString(string: title, attributes: attrs)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = hoverTrackingArea {
            removeTrackingArea(existing)
        }
        hoverTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(hoverTrackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isMouseOver = true
        NSAnimationContext.runAnimationGroup { [weak self] context in
            context.duration = 0.1
            context.allowsImplicitAnimation = true
            guard let layer = self?.layer, let title = self?.title else { return }
            if self?.buttonStyle == .neutral {
                layer.backgroundColor = NSColor.themeAdaptiveTertiaryBackground.cgColor
            } else {
                layer.backgroundColor = NSColor.themeAdaptiveDestructive.cgColor
                let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white]
                self?.attributedTitle = NSAttributedString(string: title, attributes: attrs)
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        isMouseOver = false
        NSAnimationContext.runAnimationGroup { [weak self] context in
            context.duration = 0.1
            context.allowsImplicitAnimation = true
            self?.updateAppearance()
        }
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 32)
    }
}
