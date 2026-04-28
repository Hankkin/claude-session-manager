import AppKit

class PrimaryButton: NSButton {

    enum Style {
        case accent
        case destructive
    }

    var buttonStyle: Style = .accent {
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

    convenience init(title: String, style: Style = .accent) {
        self.init(frame: .zero)
        self.title = title
        self.buttonStyle = style
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 8  // Layout.cornerRadiusMedium
        layer?.masksToBounds = true

        font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        bezelStyle = .inline
        isBordered = false
        updateAppearance()
    }

    private func updateAppearance() {
        guard let layer = layer else { return }

        let bgColor: NSColor
        switch buttonStyle {
        case .accent:
            bgColor = NSColor.themeAdaptiveAccent
        case .destructive:
            bgColor = NSColor.themeAdaptiveDestructive
        }
        layer.backgroundColor = bgColor.cgColor

        // Add shadow for depth
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOffset = NSSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.15
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
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            if buttonStyle == .accent {
                layer?.backgroundColor = NSColor(red: 0.0, green: 0.44, blue: 0.93, alpha: 1.0).cgColor
                layer?.shadowOpacity = 0.25
            } else {
                layer?.backgroundColor = NSColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0).cgColor
                layer?.shadowOpacity = 0.25
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        isMouseOver = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.allowsImplicitAnimation = true
            updateAppearance()
        }
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 44)
    }
}
