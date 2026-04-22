import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct claude_usageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = UsageViewModel()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(viewModel: viewModel) {
                updaterController.checkForUpdates(nil)
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: menuBarIcon)
                if viewModel.isLoggedIn && viewModel.lastUpdated != nil {
                    Text("\(viewModel.displayPercentage)%")
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarIcon: String {
        guard viewModel.isLoggedIn, viewModel.lastUpdated != nil else { return "c.circle" }
        switch viewModel.usageLevel {
        case .normal: return "c.circle.fill"
        case .warning: return "c.circle.fill"
        case .danger: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}
