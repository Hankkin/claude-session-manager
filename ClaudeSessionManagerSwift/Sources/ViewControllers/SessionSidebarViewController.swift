import AppKit

protocol SessionSidebarViewControllerDelegate: AnyObject {
    func sidebarDidSelectSession(_ session: Session)
    func sidebarDidEnterSelectMode()
    func sidebarDidRequestDeleteSelected()
    func sidebarDidRequestDeleteSession(_ session: Session)
    func sidebarDidRequestCopySessionId(_ sessionId: String)
}

class SessionSidebarViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    weak var delegate: SessionSidebarViewControllerDelegate?

    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var emptyStateView: EmptyStateView!
    private var loadMoreButton: NSButton!
    private var searchField: NSSearchField!
    private var headerView: NSView!
    private var selectButton: NSButton!
    private var selectionBar: SelectionBarView!

    private var sessionData: [Session] = []
    private var filteredData: [Session] = []
    private var selectedSession: Session?
    private var isSelectMode = false
    private var selectedSessions: Set<String> = []
    private var searchQuery = ""

    var sessionManager: SessionManager!

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.themeBackgroundSecondary.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        // Header with search and select button
        headerView = NSView()
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.themeBackgroundSecondary.cgColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Select button (right side of header)
        selectButton = NSButton(title: "选择", target: self, action: #selector(toggleSelectMode))
        selectButton.bezelStyle = .rounded
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(selectButton)

        // Search field
        searchField = NSSearchField()
        searchField.placeholderString = "搜索会话..."
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.sendsSearchStringImmediately = true
        headerView.addSubview(searchField)

        // Table view
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.rowHeight = 72  // Layout.sessionRowHeight
        tableView.selectionHighlightStyle = .none
        tableView.backgroundColor = .clear
        tableView.intercellSpacing = NSSize(width: 0, height: 0)

        // Right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "复制会话ID", action: #selector(copySessionIdFromMenu(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "删除会话", action: #selector(deleteFromMenu(_:)), keyEquivalent: ""))
        tableView.menu = menu

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SessionColumn"))
        column.width = 280
        tableView.addTableColumn(column)

        // Scroll view
        scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Empty state
        emptyStateView = EmptyStateView()
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)

        // Load more button
        loadMoreButton = NSButton(title: "Show More", target: self, action: #selector(loadMoreClicked))
        loadMoreButton.bezelStyle = .rounded
        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        loadMoreButton.isHidden = true
        view.addSubview(loadMoreButton)

        // Selection bar (bottom)
        selectionBar = SelectionBarView()
        selectionBar.translatesAutoresizingMaskIntoConstraints = false
        selectionBar.isHidden = true
        selectionBar.onDelete = { [weak self] in
            self?.deleteSelectedSessions()
        }
        selectionBar.onCancel = { [weak self] in
            self?.exitSelectMode()
        }
        view.addSubview(selectionBar)

        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            // Select button
            selectButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            selectButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Search field in header
            searchField.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: selectButton.leadingAnchor, constant: -8),
            searchField.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Scroll view below header
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: selectionBar.topAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),

            loadMoreButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadMoreButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            loadMoreButton.heightAnchor.constraint(equalToConstant: 28),

            // Selection bar
            selectionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectionBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            selectionBar.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    @objc private func searchChanged() {
        searchQuery = searchField.stringValue
        filterData()
        updateEmptyState()
    }

    func reloadData(sessions: [Session]) {
        sessionData = sessions
        filterData()
        updateEmptyState()
        updateLoadMoreButton()
    }

    @objc private func loadMoreClicked() {
        sessionManager.loadMoreSessions()
        reloadData(sessions: sessionManager.sessions)
    }

    private func updateLoadMoreButton() {
        let hasMore = sessionManager.hasMoreSessions
        loadMoreButton.isHidden = !hasMore || filteredData.isEmpty
        if hasMore {
            let remaining = sessionManager.remainingSessionsCount
            loadMoreButton.title = "Show More (\(remaining) remaining)"
        }
    }

    private func filterData() {
        filteredData = sessionData.filter { session in
            if !searchQuery.isEmpty {
                let query = searchQuery.lowercased()
                return session.firstMessage.lowercased().contains(query) ||
                       session.shortProject.lowercased().contains(query)
            }
            return true
        }
        tableView.reloadData()
    }

    private func updateEmptyState() {
        if filteredData.isEmpty {
            if !searchQuery.isEmpty {
                emptyStateView.state = .noSearchResults
            } else {
                emptyStateView.state = .noSessions
            }
            emptyStateView.isHidden = false
            scrollView.isHidden = true
        } else {
            emptyStateView.isHidden = true
            scrollView.isHidden = false
        }
    }

    func setSearchQuery(_ query: String) {
        searchQuery = query
        filterData()
        updateEmptyState()
    }

    func setSelectMode(_ enabled: Bool) {
        isSelectMode = enabled
        if !enabled {
            selectedSessions.removeAll()
        }
        tableView.reloadData()
    }

    func getSelectedSessionId() -> String? {
        return selectedSession?.id
    }

    func getSelectedSessionIds() -> Set<String> {
        return selectedSessions
    }

    func refresh() {
        sessionManager.loadInitialSessions()
        reloadData(sessions: sessionManager.sessions)
    }

    @objc private func toggleSelectMode() {
        if isSelectMode {
            exitSelectMode()
        } else {
            enterSelectMode()
        }
    }

    func enterSelectMode() {
        isSelectMode = true
        selectButton.title = "取消"
        selectionBar.isHidden = false
        selectionBar.updateSelection(count: selectedSessions.count)
    }

    func exitSelectMode() {
        isSelectMode = false
        selectedSessions.removeAll()
        selectButton.title = "选择"
        selectionBar.isHidden = true
        tableView.reloadData()
    }

    func clearSelection() {
        selectedSession = nil
        tableView.deselectAll(nil)
        tableView.reloadData()
    }

    @objc private func copySessionIdFromMenu(_ sender: NSMenuItem) {
        let row = tableView.clickedRow
        guard row >= 0 && row < filteredData.count else { return }
        let session = filteredData[row]
        delegate?.sidebarDidRequestCopySessionId(session.id)
    }

    @objc private func deleteFromMenu(_ sender: NSMenuItem) {
        let row = tableView.clickedRow
        guard row >= 0 && row < filteredData.count else { return }
        let session = filteredData[row]

        let alert = NSAlert()
        alert.messageText = "删除会话"
        alert.informativeText = "确定要删除这个会话吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            delegate?.sidebarDidRequestDeleteSession(session)
        }
    }

    private func deleteSelectedSessions() {
        guard !selectedSessions.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "删除 \(selectedSessions.count) 个会话"
        alert.informativeText = "确定要删除这些会话吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            for sessionId in selectedSessions {
                if let session = sessionManager.getSession(by: sessionId) {
                    delegate?.sidebarDidRequestDeleteSession(session)
                }
            }
            exitSelectMode()
        }
    }

    // MARK: - NSTableViewDelegate & DataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredData.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let session = filteredData[row]
        let identifier = NSUserInterfaceItemIdentifier("SessionRow")

        var rowView = tableView.makeView(withIdentifier: identifier, owner: nil) as? SessionRowView
        if rowView == nil {
            rowView = SessionRowView()
            rowView?.identifier = identifier
        }

        // Check both multi-select mode and single selection mode
        let isMultiSelected = selectedSessions.contains(session.id)
        let isSingleSelected = !isSelectMode && selectedSession?.id == session.id
        let isRowSelected = isMultiSelected || isSingleSelected
        rowView?.configure(with: session, isSelectMode: isSelectMode, isSelected: isRowSelected)
        return rowView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 72  // Layout.sessionRowHeight
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 && row < filteredData.count else { return }

        let session = filteredData[row]

        if isSelectMode {
            if selectedSessions.contains(session.id) {
                selectedSessions.remove(session.id)
            } else {
                selectedSessions.insert(session.id)
            }
            selectionBar.updateSelection(count: selectedSessions.count)
            tableView.reloadData()
        } else {
            selectedSession = session
            tableView.reloadData()  // Refresh to show highlight
            delegate?.sidebarDidSelectSession(session)
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}
