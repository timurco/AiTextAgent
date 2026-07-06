import AppKit

/// Tiny toast notification (150x40) shown under the menu bar icon for 2 seconds.
/// Colored header (green = success, red = failure) with flag emoji + title,
/// light body with truncated text. Click-through, never takes focus.
final class ToastWindow: NSWindow {
    enum Style {
        case success
        case failure
    }

    private static let toastSize = NSSize(width: 150, height: 40)
    private static let headerHeight: CGFloat = 16
    private static var current: ToastWindow?

    // Never steal focus from the active app
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Show a toast under the status item, auto-dismisses after 2 seconds
    static func show(style: Style, flag: String, title: String, text: String, under statusItem: NSStatusItem?) {
        // Replace any toast still on screen
        current?.orderOut(nil)
        current = nil

        let toast = ToastWindow(style: style, flag: flag, title: title, text: text)
        toast.position(under: statusItem)
        current = toast

        toast.alphaValue = 0
        toast.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            toast.animator().alphaValue = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard toast === current else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                toast.animator().alphaValue = 0
            }, completionHandler: {
                toast.orderOut(nil)
                if current === toast { current = nil }
            })
        }
    }

    private init(style: Style, flag: String, title: String, text: String) {
        let size = ToastWindow.toastSize
        super.init(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)

        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        ignoresMouseEvents = true
        hasShadow = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .transient]
        // Always light look (white body) regardless of system dark mode
        appearance = NSAppearance(named: .aqua)

        let headerHeight = ToastWindow.headerHeight
        let textColor = NSColor(white: 0.1, alpha: 1)

        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.layer?.cornerRadius = 8
        container.layer?.masksToBounds = true
        container.layer?.backgroundColor = NSColor(white: 0.98, alpha: 1).cgColor

        // Header strip: pastel green/red with flag + title
        let headerColor: NSColor = (style == .success)
            ? NSColor.systemGreen.withAlphaComponent(0.35)
            : NSColor.systemRed.withAlphaComponent(0.35)
        let header = NSView(frame: NSRect(x: 0, y: size.height - headerHeight, width: size.width, height: headerHeight))
        header.wantsLayer = true
        header.layer?.backgroundColor = headerColor.cgColor

        let headerLabel = NSTextField(labelWithString: "\(flag) \(title)")
        headerLabel.frame = NSRect(x: 6, y: 2, width: size.width - 12, height: 12)
        headerLabel.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        headerLabel.textColor = textColor
        headerLabel.lineBreakMode = .byTruncatingTail
        header.addSubview(headerLabel)

        // Body: single truncated line of text
        let bodyHeight = size.height - headerHeight
        let bodyLabel = NSTextField(labelWithString: ToastWindow.oneLine(text))
        bodyLabel.frame = NSRect(x: 6, y: (bodyHeight - 14) / 2, width: size.width - 12, height: 14)
        bodyLabel.font = NSFont.systemFont(ofSize: 10)
        bodyLabel.textColor = textColor
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.maximumNumberOfLines = 1

        container.addSubview(header)
        container.addSubview(bodyLabel)
        contentView = container
    }

    /// Collapse newlines/whitespace into a single display line
    private static func oneLine(_ text: String) -> String {
        return text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Place the toast centered right below the status item icon
    private func position(under statusItem: NSStatusItem?) {
        guard let button = statusItem?.button,
              let buttonWindow = button.window,
              let screen = buttonWindow.screen ?? NSScreen.main else {
            // Fallback: top-right corner of the main screen
            if let visible = NSScreen.main?.visibleFrame {
                setFrameOrigin(NSPoint(x: visible.maxX - frame.width - 8, y: visible.maxY - frame.height - 8))
            }
            return
        }

        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        var x = buttonRect.midX - frame.width / 2
        let y = buttonRect.minY - frame.height - 6

        // Keep on screen
        x = min(max(x, screen.visibleFrame.minX + 4), screen.visibleFrame.maxX - frame.width - 4)
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
