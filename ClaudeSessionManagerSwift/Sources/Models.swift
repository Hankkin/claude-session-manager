import Foundation

struct Session: Identifiable {
    let id: String
    let project: String
    let firstMessage: String
    let timestamp: Int
    var messageCount: Int
    var isPinned: Bool = false

    var formattedTime: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "今天 \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "昨天 \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
    }

    var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    var shortProject: String {
        if project == "/Users/hankkin" {
            return "~"
        }
        return project
            .replacingOccurrences(of: "/Users/hankkin/", with: "~/")
            .replacingOccurrences(of: "-Users-hankkin", with: "~")
    }

    var truncatedMessage: String {
        let msg = firstMessage.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        if msg.count > 150 {
            return String(msg.prefix(150)) + "..."
        }
        return msg
    }

    /// WeCLaude sessions are stored in ~/.claude/projects/-Users-hankkin--weclaw-workspace/
    var isWeCLaudeSession: Bool {
        let projectsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
        let sessionFile = projectsDir.appendingPathComponent("-Users-hankkin--weclaw-workspace/\(id).jsonl")
        return FileManager.default.fileExists(atPath: sessionFile.path)
    }
}

class SessionManager {
    private(set) var sessions: [Session] = []
    private var allSessions: [Session] = []  // Complete list before pagination
    private let pageSize: Int = 20

    private let pinnedSessionsKey = "pinnedSessionIds"

    var hasMoreSessions: Bool {
        return sessions.count < allSessions.count
    }

    var remainingSessionsCount: Int {
        return max(0, allSessions.count - sessions.count)
    }

    private var pinnedSessionIds: Set<String> {
        get {
            let defaults = UserDefaults.standard
            let array = defaults.stringArray(forKey: pinnedSessionsKey) ?? []
            return Set(array)
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(Array(newValue), forKey: pinnedSessionsKey)
        }
    }

    func togglePin(for sessionId: String) {
        var pinned = pinnedSessionIds
        if pinned.contains(sessionId) {
            pinned.remove(sessionId)
        } else {
            pinned.insert(sessionId)
        }
        pinnedSessionIds = pinned

        // Update session's isPinned property in both lists
        updatePinnedStatus()
    }

    private func updatePinnedStatus() {
        for i in 0..<sessions.count {
            sessions[i].isPinned = pinnedSessionIds.contains(sessions[i].id)
        }
        for i in 0..<allSessions.count {
            allSessions[i].isPinned = pinnedSessionIds.contains(allSessions[i].id)
        }
    }

    func isPinned(_ sessionId: String) -> Bool {
        return pinnedSessionIds.contains(sessionId)
    }

    func loadInitialSessions() {
        loadAllSessions()
        // Load first page
        sessions = Array(allSessions.prefix(pageSize))
    }

    func loadMoreSessions() {
        guard hasMoreSessions else { return }
        let currentCount = sessions.count
        let nextBatch = Array(allSessions.prefix(currentCount + pageSize))
        sessions = nextBatch
    }

    private var historyPath: String {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/history.jsonl").path
    }

    private func loadAllSessions() {
        // Load from history.jsonl
        let historyFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/history.jsonl")

        var newSessions: [Session] = []

        if let content = try? String(contentsOfFile: historyFile.path, encoding: .utf8) {
            let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

            // Group by sessionId
            var grouped: [String: [[String: Any]]] = [:]

            for line in lines {
                guard let data = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let sessionId = json["sessionId"] as? String else {
                    continue
                }
                if grouped[sessionId] == nil {
                    grouped[sessionId] = []
                }
                grouped[sessionId]?.append(json)
            }

            // Build sessions from history.jsonl
            for (sessionId, entries) in grouped {
                let sorted = entries.sorted { ($0["timestamp"] as? Int ?? 0) < ($1["timestamp"] as? Int ?? 0) }

                var firstMsg = ""
                var project = ""
                var timestamp = 0

                for entry in sorted {
                    if let display = entry["display"] as? String, !display.isEmpty, firstMsg.isEmpty {
                        firstMsg = String(display.prefix(100))
                    }
                    if let proj = entry["project"] as? String, !proj.isEmpty, project.isEmpty {
                        project = proj
                    }
                    timestamp = max(timestamp, entry["timestamp"] as? Int ?? 0)
                }

                if !firstMsg.isEmpty {
                    newSessions.append(Session(
                        id: sessionId,
                        project: project.isEmpty ? "~" : project,
                        firstMessage: firstMsg,
                        timestamp: timestamp,
                        messageCount: entries.count
                    ))
                }
            }
        }

        // Also load WeCLaude sessions from its workspace directory
        let weclawDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects/-Users-hankkin--weclaw-workspace")

        if let enumerator = FileManager.default.enumerator(at: weclawDir, includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey]) {
            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension == "jsonl" else { continue }

                let sessionId = url.deletingPathExtension().lastPathComponent
                // Skip if already loaded from history.jsonl
                if newSessions.contains(where: { $0.id == sessionId }) {
                    continue
                }

                if let session = loadWeCLaudeSession(from: url) {
                    newSessions.append(session)
                }
            }
        }

        // Sort by timestamp descending, pinned sessions first
        let pinned = pinnedSessionIds
        newSessions.sort { s1, s2 in
            if pinned.contains(s1.id) && !pinned.contains(s2.id) {
                return true
            } else if !pinned.contains(s1.id) && pinned.contains(s2.id) {
                return false
            }
            return s1.timestamp > s2.timestamp
        }

        // Apply isPinned flag
        for i in 0..<newSessions.count {
            newSessions[i].isPinned = pinned.contains(newSessions[i].id)
        }

        // Store all sessions (pagination handled by callers)
        allSessions = newSessions
    }

    private func loadWeCLaudeSession(from fileURL: URL) -> Session? {
        guard let content = try? String(contentsOfFile: fileURL.path, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        var firstMsg = ""
        var timestamp: Int = 0
        var messageCount = 0

        for line in lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                continue
            }

            // Get timestamp from the line
            if let ts = json["timestamp"] as? Int {
                timestamp = max(timestamp, ts)
            } else if let tsString = json["timestamp"] as? String {
                // Parse ISO8601 timestamp string
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: tsString) {
                    timestamp = max(timestamp, Int(date.timeIntervalSince1970 * 1000))
                } else {
                    formatter.formatOptions = [.withInternetDateTime]
                    if let date = formatter.date(from: tsString) {
                        timestamp = max(timestamp, Int(date.timeIntervalSince1970 * 1000))
                    }
                }
            }

            // Extract first message
            if firstMsg.isEmpty {
                if type == "user" {
                    // Try display field first
                    if let display = json["display"] as? String, !display.isEmpty {
                        firstMsg = String(display.prefix(100))
                    } else if let message = json["message"] as? [String: Any] {
                        if let content = message["content"] as? String, !content.isEmpty {
                            firstMsg = String(content.prefix(100))
                        } else if let contentList = message["content"] as? [[String: Any]] {
                            for c in contentList {
                                if let cType = c["type"] as? String, cType == "text",
                                   let text = c["text"] as? String, !text.isEmpty {
                                    firstMsg = String(text.prefix(100))
                                    break
                                }
                            }
                        }
                    }
                }
            }

            // Count user messages
            if type == "user" || type == "assistant" {
                messageCount += 1
            }
        }

        guard !firstMsg.isEmpty else { return nil }

        return Session(
            id: fileURL.deletingPathExtension().lastPathComponent,
            project: "~/.claude/projects/-Users-hankkin--weclaw-workspace",
            firstMessage: firstMsg,
            timestamp: timestamp,
            messageCount: messageCount
        )
    }

    func getSession(by id: String) -> Session? {
        return sessions.first { $0.id == id }
    }

    func deleteSession(sessionId: String) -> Bool {
        let historyFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/history.jsonl")

        guard let content = try? String(contentsOfFile: historyFile.path, encoding: .utf8) else {
            return false
        }

        let lines = content.components(separatedBy: "\n")
        var remainingLines: [String] = []
        var deleted = false

        for line in lines {
            if line.isEmpty { continue }

            if let data = line.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sid = json["sessionId"] as? String,
               sid == sessionId {
                deleted = true
                continue
            }
            remainingLines.append(line)
        }

        let newContent = remainingLines.joined(separator: "\n") + "\n"
        try? newContent.write(to: historyFile, atomically: true, encoding: .utf8)

        return deleted
    }

    // Cache for session file paths to avoid repeated directory searches
    private var sessionFileCache: [String: URL] = [:]

    func loadSessionContent(session: Session, maxLines: Int = 30, offset: Int = 0) -> String {
        let projectsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")

        // Check cache first
        if let cachedPath = sessionFileCache[session.id] {
            return loadContentFromFile(cachedPath, maxLines: maxLines, offset: offset)
        }

        var sessionFile: URL?

        // First try: direct path with computed hash
        let projectHash = session.project
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "~", with: "-Users-hankkin")
        let directPath = projectsDir.appendingPathComponent("\(projectHash)/\(session.id).jsonl")
        if FileManager.default.fileExists(atPath: directPath.path) {
            sessionFile = directPath
        }

        // Second try: search in all project directories
        if sessionFile == nil {
            let maxProjectsToSearch = 50
            var projectsSearched = 0

            guard let enumerator = FileManager.default.enumerator(at: projectsDir, includingPropertiesForKeys: [.isDirectoryKey, .nameKey]) else {
                return "会话文件未找到: \(session.id)"
            }

            while let url = enumerator.nextObject() as? URL {
                // Get resource values once
                var resourceValues: URLResourceValues?
                do {
                    resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                } catch {
                    continue
                }

                // Skip if not a directory
                guard resourceValues?.isDirectory == true else {
                    continue
                }

                projectsSearched += 1
                if projectsSearched > maxProjectsToSearch {
                    break
                }

                // Look for session file in this project
                let sessionPath = url.appendingPathComponent("\(session.id).jsonl")
                if FileManager.default.fileExists(atPath: sessionPath.path) {
                    sessionFile = sessionPath
                    break
                }

                // Skip subdirectories within this project
                enumerator.skipDescendants()
            }
        }

        guard let file = sessionFile else {
            return "会话文件未找到: \(session.id)"
        }

        // Cache the found path
        sessionFileCache[session.id] = file

        return loadContentFromFile(file, maxLines: maxLines, offset: offset)
    }

    private func loadContentFromFile(_ file: URL, maxLines: Int, offset: Int) -> String {
        guard let content = try? String(contentsOfFile: file.path, encoding: .utf8) else {
            return "会话文件未找到: \(file.lastPathComponent)"
        }

        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        var result: [String] = []
        var userCount = 0
        var assistantCount = 0
        var visibleCount = 0  // Count only messages with actual content for proper offset
        var messagesCollected = 0

        for line in lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                continue
            }

            if type == "user" {
                var content = json["display"] as? String ?? ""

                if content.isEmpty,
                   let message = json["message"] as? [String: Any] {
                    if let text = message["content"] as? String {
                        content = text
                    } else if let contentList = message["content"] as? [[String: Any]] {
                        for c in contentList {
                            if let cType = c["type"] as? String, cType == "text",
                               let text = c["text"] as? String {
                                content = text
                                break
                            }
                        }
                    }
                }

                if !content.isEmpty {
                    // Skip messages before offset using visible count (not entry count)
                    if visibleCount < offset {
                        visibleCount += 1
                        continue
                    }

                    userCount += 1
                    visibleCount += 1
                    result.append("[用户 \(userCount)]\n\(String(content.prefix(500)))")
                    messagesCollected += 1

                    if messagesCollected >= maxLines {
                        break
                    }
                }
            } else if type == "assistant" {
                var assistantContent = ""
                if let message = json["message"] as? [String: Any],
                   let contentList = message["content"] as? [[String: Any]] {
                    for c in contentList {
                        if let cType = c["type"] as? String, cType == "text",
                           let text = c["text"] as? String {
                            assistantContent = text
                            break
                        }
                    }
                }

                if !assistantContent.isEmpty {
                    // Skip messages before offset using visible count
                    if visibleCount < offset {
                        visibleCount += 1
                        continue
                    }

                    assistantCount += 1
                    visibleCount += 1
                    result.append("[助手 \(assistantCount)]\n\(String(assistantContent.prefix(800)))")
                    messagesCollected += 1

                    if messagesCollected >= maxLines {
                        break
                    }
                }
            }
        }

        return result.isEmpty ? "会话内容为空" : result.joined(separator: "\n\n")
    }

    /// Check if there are more messages beyond the current offset
    func hasMoreContent(session: Session, afterOffset offset: Int, maxLines: Int = 20) -> Bool {
        guard let cachedPath = sessionFileCache[session.id] else {
            // If not cached, we can't know without loading - return true to show load more
            return true
        }

        guard let content = try? String(contentsOfFile: cachedPath.path, encoding: .utf8) else {
            return false
        }

        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        var visibleCount = 0  // Count only messages with actual content

        for line in lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                continue
            }

            var hasVisibleContent = false

            if type == "user" {
                let display = json["display"] as? String ?? ""
                var msgContent = display
                if msgContent.isEmpty, let message = json["message"] as? [String: Any] {
                    if let text = message["content"] as? String {
                        msgContent = text
                    } else if let contentList = message["content"] as? [[String: Any]] {
                        for c in contentList {
                            if let cType = c["type"] as? String, cType == "text",
                               let text = c["text"] as? String {
                                msgContent = text
                                break
                            }
                        }
                    }
                }
                if !msgContent.isEmpty {
                    hasVisibleContent = true
                }
            } else if type == "assistant" {
                if let message = json["message"] as? [String: Any],
                   let contentList = message["content"] as? [[String: Any]] {
                    for c in contentList {
                        if let cType = c["type"] as? String, cType == "text",
                           let text = c["text"] as? String, !text.isEmpty {
                            hasVisibleContent = true
                            break
                        }
                    }
                }
            }

            if hasVisibleContent {
                // Only count visible messages for offset comparison
                if visibleCount >= offset {
                    // This message is at or after our offset, count it
                    visibleCount += 1
                    // If we've collected maxLines after offset, there might be more
                    if visibleCount > offset + maxLines {
                        return true
                    }
                } else {
                    visibleCount += 1
                }
            }
        }

        // We have more if visibleCount > offset + maxLines
        return visibleCount > offset + maxLines
    }
}
