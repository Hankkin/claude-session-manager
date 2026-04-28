import AppKit

class Divider: NSView {

    var isVertical: Bool = false {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.themeAdaptiveBorder.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.themeAdaptiveBorder.cgColor
    }

    convenience init(vertical: Bool = false) {
        self.init(frame: .zero)
        isVertical = vertical
    }

    override var intrinsicContentSize: NSSize {
        if isVertical {
            return NSSize(width: Layout.dividerThickness, height: NSView.noIntrinsicMetric)
        } else {
            return NSSize(width: NSView.noIntrinsicMetric, height: Layout.dividerThickness)
        }
    }
}
