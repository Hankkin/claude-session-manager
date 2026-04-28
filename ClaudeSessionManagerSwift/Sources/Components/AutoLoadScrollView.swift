import AppKit

class AutoLoadScrollView: NSScrollView {

    var onScrollNearBottom: (() -> Void)?

    override func reflectScrolledClipView(_ clipView: NSClipView) {
        super.reflectScrolledClipView(clipView)
        checkIfNearBottom()
    }

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        checkIfNearBottom()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let docView = documentView {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(documentViewDidChange),
                name: NSView.frameDidChangeNotification,
                object: docView
            )
        }
    }

    @objc private func documentViewDidChange(_ notification: Notification) {
        checkIfNearBottom()
    }

    private func checkIfNearBottom() {
        guard let docView = documentView else { return }

        let clipView = self.contentView
        let visibleRect = clipView.bounds
        let documentHeight = docView.frame.height
        let scrollPosition = visibleRect.origin.y
        let threshold: CGFloat = 100

        // Load more when scrolled to TOP or BOTTOM
        if scrollPosition <= threshold || scrollPosition >= documentHeight - threshold {
            onScrollNearBottom?()
        }
    }

    deinit {
        if let docView = documentView {
            NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: docView)
        }
    }
}
