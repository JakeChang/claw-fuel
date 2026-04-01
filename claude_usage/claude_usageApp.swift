import SwiftUI

@main
struct claude_usageApp: App {
    @State private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(viewModel: viewModel)
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

        Window("登入 Claude", id: "login") {
            LoginWebView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
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
