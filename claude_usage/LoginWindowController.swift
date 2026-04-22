import AppKit
import SwiftUI

enum LoginWindowController {
    private static var window: NSWindow?

    @MainActor
    static func show(viewModel: UsageViewModel) {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        let loginView = LoginWebView(viewModel: viewModel) { [weak newWindow] in
            newWindow?.close()
        }
        newWindow.contentView = NSHostingView(rootView: loginView)
        newWindow.title = String(localized: "login.title")
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }
}
