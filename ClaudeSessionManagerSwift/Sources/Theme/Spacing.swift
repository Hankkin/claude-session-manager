import AppKit

enum Spacing {
    /// 4pt - Icon-to-text, tight grouping
    static let xs: CGFloat = 4

    /// 8pt - Between related elements
    static let sm: CGFloat = 8

    /// 12pt - Padding within components
    static let md: CGFloat = 12

    /// 16pt - Standard padding, margins
    static let lg: CGFloat = 16

    /// 24pt - Section separation
    static let xl: CGFloat = 24

    /// 32pt - Large gaps
    static let xxl: CGFloat = 32

    /// 48pt - Hero spacing
    static let xxxl: CGFloat = 48
}

enum Layout {
    /// Session row height
    static let sessionRowHeight: CGFloat = 72

    /// Sidebar width
    static let sidebarWidth: CGFloat = 280

    /// Sidebar minimum width
    static let sidebarMinWidth: CGFloat = 200

    /// Sidebar maximum width
    static let sidebarMaxWidth: CGFloat = 400

    /// Search field height
    static let searchFieldHeight: CGFloat = 28

    /// Primary button height
    static let primaryButtonHeight: CGFloat = 44

    /// Secondary button height
    static let secondaryButtonHeight: CGFloat = 32

    /// Divider thickness
    static let dividerThickness: CGFloat = 0.5

    /// Corner radius small
    static let cornerRadiusSmall: CGFloat = 6

    /// Corner radius medium
    static let cornerRadiusMedium: CGFloat = 8

    /// Corner radius large
    static let cornerRadiusLarge: CGFloat = 12

    /// Selection border width
    static let selectionBorderWidth: CGFloat = 2

    /// Toolbar height
    static let toolbarHeight: CGFloat = 38
}
