import AppKit

extension NSFont {

    // MARK: - Typography Scale

    /// Window title - 13pt semibold
    static var themeWindowTitle: NSFont {
        return .systemFont(ofSize: 13, weight: .semibold)
    }

    /// Section header - 11pt semibold
    static var themeSectionHeader: NSFont {
        return .systemFont(ofSize: 11, weight: .semibold)
    }

    /// Session title - 14pt medium
    static var themeSessionTitle: NSFont {
        return .systemFont(ofSize: 14, weight: .medium)
    }

    /// Session preview - 13pt regular
    static var themeSessionPreview: NSFont {
        return .systemFont(ofSize: 13, weight: .regular)
    }

    /// Session meta (timestamps, counts) - 11pt regular
    static var themeSessionMeta: NSFont {
        return .systemFont(ofSize: 11, weight: .regular)
    }

    /// Detail content - 13pt regular
    static var themeDetailContent: NSFont {
        return .systemFont(ofSize: 13, weight: .regular)
    }

    /// Session ID - 10pt monospace
    static var themeSessionId: NSFont {
        return .monospacedSystemFont(ofSize: 10, weight: .regular)
    }

    /// Button text - 13pt medium
    static var themeButton: NSFont {
        return .systemFont(ofSize: 13, weight: .medium)
    }

    /// Small button text - 12pt medium
    static var themeButtonSmall: NSFont {
        return .systemFont(ofSize: 12, weight: .medium)
    }

    /// Toolbar search - 12pt regular
    static var themeSearch: NSFont {
        return .systemFont(ofSize: 12, weight: .regular)
    }

    /// Hero button - 14pt semibold
    static var themeHeroButton: NSFont {
        return .systemFont(ofSize: 14, weight: .semibold)
    }

    /// Empty state title - 16pt semibold
    static var themeEmptyStateTitle: NSFont {
        return .systemFont(ofSize: 16, weight: .semibold)
    }

    /// Empty state subtitle - 13pt regular
    static var themeEmptyStateSubtitle: NSFont {
        return .systemFont(ofSize: 13, weight: .regular)
    }
}
