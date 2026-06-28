import CoreGraphics

enum AppShellLayout {
    static let separatorWidth: CGFloat = 1

    static func sidebarWidth(containerWidth: CGFloat, isSidebarCollapsed: Bool) -> CGFloat {
        AssistantSidebarLayout.width(
            containerWidth: containerWidth,
            isCollapsed: isSidebarCollapsed
        )
    }

    static func contentWidth(containerWidth: CGFloat, isSidebarCollapsed: Bool) -> CGFloat {
        let reservedSidebarWidth = sidebarWidth(
            containerWidth: containerWidth,
            isSidebarCollapsed: isSidebarCollapsed
        )
        let reservedSeparatorWidth = reservedSidebarWidth > 0 ? separatorWidth : 0

        return max(0, containerWidth - reservedSidebarWidth - reservedSeparatorWidth)
    }
}
