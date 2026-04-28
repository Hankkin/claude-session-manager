import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!
    private var sessionManager: SessionManager!
    private var splitViewController: MainSplitViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        sessionManager = SessionManager()
        sessionManager.loadInitialSessions()

        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1100, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Claude Sessions"
        window.minSize = NSSize(width: 900, height: 500)

        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.wantsLayer = true
        window.contentView = contentView

        // Split view controller - test without it first
        splitViewController = MainSplitViewController()
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(splitViewController.view)

        NSLayoutConstraint.activate([
            splitViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Setup
        splitViewController.sidebarViewController.delegate = self
        splitViewController.sidebarViewController.sessionManager = sessionManager
        splitViewController.detailViewController.delegate = self
        splitViewController.sidebarViewController.reloadData(sessions: sessionManager.sessions)

        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - SessionSidebarViewControllerDelegate
extension AppDelegate: SessionSidebarViewControllerDelegate {
    func sidebarDidSelectSession(_ session: Session) {
        splitViewController.detailViewController.configure(with: session, manager: sessionManager)
    }

    func sidebarDidEnterSelectMode() {}
    func sidebarDidRequestDeleteSelected() {}
    func sidebarDidRequestDeleteSession(_ session: Session) {
        if sessionManager.deleteSession(sessionId: session.id) {
            // Reload sessions from file to update the in-memory list
            sessionManager.loadInitialSessions()
            splitViewController.sidebarViewController.reloadData(sessions: sessionManager.sessions)
            splitViewController.sidebarViewController.clearSelection()
            splitViewController.detailViewController.clear()
        }
    }
    func sidebarDidRequestCopySessionId(_ sessionId: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(sessionId, forType: .string)
    }
}

// MARK: - SessionDetailViewControllerDelegate
extension AppDelegate: SessionDetailViewControllerDelegate {
    func detailDidRequestResume(_ session: Session) {
        let sessionId = session.id
        let project = session.project

        // 构建命令
        var command = ""
        if !project.isEmpty && project != "~" {
            command = "cd \"\(project)\" && claude --resume \(sessionId)"
        } else {
            command = "claude --resume \(sessionId)"
        }

        // 复制命令到剪贴板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)

        // 激活 Ghostty
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Ghostty.app"))

        // 显示通知提示用户
        self.showNotification(
            "Resume 命令已复制",
            "在 Ghostty 中按 Cmd+V 粘贴命令，然后按回车"
        )
    }

    private func showNotification(_ title: String, _ message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }

    func detailDidRequestCopyId(_ sessionId: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(sessionId, forType: .string)
    }

    func detailDidRequestDelete(_ session: Session) {
        if sessionManager.deleteSession(sessionId: session.id) {
            splitViewController.sidebarViewController.reloadData(sessions: sessionManager.sessions)
            splitViewController.detailViewController.clear()
        }
    }

    func detailDidTogglePin(_ session: Session) {
        sessionManager.togglePin(for: session.id)
        splitViewController.sidebarViewController.reloadData(sessions: sessionManager.sessions)
    }
}
