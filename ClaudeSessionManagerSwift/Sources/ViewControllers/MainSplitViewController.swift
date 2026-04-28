import AppKit

class MainSplitViewController: NSSplitViewController {

    let sidebarViewController = SessionSidebarViewController()
    let detailViewController = SessionDetailViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSplitView()
    }

    private func setupSplitView() {
        // Sidebar item
        let sidebarItem = NSSplitViewItem()
        sidebarItem.viewController = sidebarViewController
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 400
        sidebarItem.canCollapse = false
        addSplitViewItem(sidebarItem)

        // Detail item
        let detailItem = NSSplitViewItem()
        detailItem.viewController = detailViewController
        detailItem.minimumThickness = 400
        addSplitViewItem(detailItem)

        // Split view properties
        splitView.isVertical = true
        splitView.dividerStyle = .thin
    }
}
