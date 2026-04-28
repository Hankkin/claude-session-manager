import AppKit

extension NSColor {

    // MARK: - Accent Colors (Figma Blue #0066FF)

    static var themeAccent: NSColor {
        return NSColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)
    }

    static var themeAccentHover: NSColor {
        return NSColor(red: 0.0, green: 0.44, blue: 0.93, alpha: 1.0)
    }

    // MARK: - Destructive

    static var themeDestructive: NSColor {
        return NSColor.systemRed
    }

    // MARK: - Semantic Colors (auto-adapt to light/dark)

    static var themeBackgroundPrimary: NSColor {
        return .windowBackgroundColor
    }

    static var themeBackgroundSecondary: NSColor {
        return .controlBackgroundColor
    }

    static var themeBackgroundTertiary: NSColor {
        return .underPageBackgroundColor
    }

    static var themeBackgroundSelected: NSColor {
        return .selectedContentBackgroundColor
    }

    // MARK: - Text Colors

    static var themeTextPrimary: NSColor {
        return .labelColor
    }

    static var themeTextSecondary: NSColor {
        return .secondaryLabelColor
    }

    static var themeTextTertiary: NSColor {
        return .tertiaryLabelColor
    }

    // MARK: - Border

    static var themeBorder: NSColor {
        return .separatorColor
    }

    // MARK: - Adaptive (for when we need specific light/dark)

    static var themeAdaptiveAccent: NSColor {
        return NSColor(name: "FigmaAccent") { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)  // #0A84FF
            } else {
                return NSColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)      // #0066FF
            }
        }
    }

    static var themeAdaptiveDestructive: NSColor {
        return NSColor(name: "FigmaDestructive") { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)   // #FF453A
            } else {
                return NSColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)   // #FF3B30
            }
        }
    }

    static var themeAdaptiveSecondaryBackground: NSColor {
        return NSColor(name: "FigmaSecondaryBG") { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)  // #2C2C2E
            } else {
                return NSColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)   // #F7F7F7
            }
        }
    }

    static var themeAdaptiveTertiaryBackground: NSColor {
        return NSColor(name: "FigmaTertiaryBG") { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 0.23, green: 0.23, blue: 0.24, alpha: 1.0)  // #3A3A3C
            } else {
                return NSColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)  // #F0F0F0
            }
        }
    }

    static var themeAdaptiveBorder: NSColor {
        return NSColor(name: "FigmaBorder") { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 0.22, green: 0.22, blue: 0.23, alpha: 1.0)  // #38383A
            } else {
                return NSColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0)  // #E5E5E5
            }
        }
    }

    static var themeAdaptiveSelectedBackground: NSColor {
        return NSColor(name: "FigmaSelectedBG") { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: 0.28, green: 0.28, blue: 0.29, alpha: 1.0)  // #48484A
            } else {
                return NSColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1.0)  // #E8E8E8
            }
        }
    }
}
