import Foundation
import Observation
import ServiceManagement
import UserNotifications
import WidgetKit

@Observable
class UsageViewModel {
    var sessionUtilization: Double = 0
    var weeklyUtilization: Double = 0
    var sessionResetsAt: Date?
    var weeklyResetsAt: Date?
    var weeklySonnetUtilization: Double?
    var weeklySonnetResetsAt: Date?
    var lastUpdated: Date?
    var isLoading = false
    var error: String?
    var isLoggedIn = false
    var usageHistory: [UsageRecord] = []

    private var refreshTask: Task<Void, Never>?
    private var hasNotified90Session = false
    private var hasNotified90Weekly = false
    private var lastScheduledSessionReset: Date?
    private var lastScheduledWeeklyReset: Date?

    var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    var showRemaining: Bool = UserDefaults.standard.bool(forKey: "showRemaining") {
        didSet { UserDefaults.standard.set(showRemaining, forKey: "showRemaining") }
    }

    var displayPercentage: Int {
        let value = showRemaining ? (1.0 - sessionUtilization) : sessionUtilization
        return Int(value * 100)
    }
    var usageLevel: UsageLevel { UsageLevel.from(sessionUtilization) }

    init() {
        loadCookies()
        loadHistory()
        requestNotificationPermission()
        startAutoRefresh()
    }

    // MARK: - Auto Refresh

    private func startAutoRefresh() {
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(300))
            }
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func checkAndNotify() {
        if sessionUtilization >= 0.9 && !hasNotified90Session {
            hasNotified90Session = true
            sendNotification(
                id: "session-90",
                title: String(localized: "notif.session.warning.title"),
                body: String(format: String(localized: "notif.session.warning.body"), Int(sessionUtilization * 100))
            )
        } else if sessionUtilization < 0.9 {
            hasNotified90Session = false
        }

        if weeklyUtilization >= 0.9 && !hasNotified90Weekly {
            hasNotified90Weekly = true
            sendNotification(
                id: "weekly-90",
                title: String(localized: "notif.weekly.warning.title"),
                body: String(format: String(localized: "notif.weekly.warning.body"), Int(weeklyUtilization * 100))
            )
        } else if weeklyUtilization < 0.9 {
            hasNotified90Weekly = false
        }

        if let resetAt = sessionResetsAt, resetAt != lastScheduledSessionReset {
            lastScheduledSessionReset = resetAt
            scheduleResetNotification(id: "session-reset", at: resetAt, title: String(localized: "notif.session.reset.title"))
        }
        if let resetAt = weeklyResetsAt, resetAt != lastScheduledWeeklyReset {
            lastScheduledWeeklyReset = resetAt
            scheduleResetNotification(id: "weekly-reset", at: resetAt, title: String(localized: "notif.weekly.reset.title"))
        }
    }

    private func sendNotification(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleResetNotification(id: String, at date: Date, title: String) {
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = String(localized: "notif.reset.body")
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Usage History

    private func recordHistory() {
        let record = UsageRecord(date: Date(), session: sessionUtilization, weekly: weeklyUtilization)
        usageHistory.append(record)
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        usageHistory = usageHistory.filter { $0.date > cutoff }
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(usageHistory) {
            UserDefaults.standard.set(data, forKey: "claude_usage_history")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: "claude_usage_history"),
              let history = try? JSONDecoder().decode([UsageRecord].self, from: data) else { return }
        let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
        usageHistory = history.filter { $0.date > cutoff }
    }

    // MARK: - Widget Sync

    private func writeToSharedDefaults() {
        let shared = SharedUsageData(
            sessionUtilization: sessionUtilization,
            weeklyUtilization: weeklyUtilization,
            weeklySonnetUtilization: weeklySonnetUtilization,
            sessionResetsAt: sessionResetsAt,
            weeklyResetsAt: weeklyResetsAt,
            weeklySonnetResetsAt: weeklySonnetResetsAt,
            lastUpdated: lastUpdated ?? Date(),
            isLoggedIn: isLoggedIn
        )
        AppGroupConstants.write(shared)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Cookie Management

    func handleLoginSuccess(cookies: [HTTPCookie]) {
        let claudeCookies = cookies.filter { $0.domain.contains("claude.ai") }
        for cookie in claudeCookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        saveCookies(claudeCookies)
        isLoggedIn = true
        Task { await refresh() }
    }

    func logout() {
        clearCookies()
        isLoggedIn = false
        sessionUtilization = 0
        weeklyUtilization = 0
        weeklySonnetUtilization = nil
        lastUpdated = nil
        error = nil
        writeToSharedDefaults()
    }

    private func saveCookies(_ cookies: [HTTPCookie]) {
        let data = cookies.compactMap { $0.properties }.map { dict in
            var serializable: [String: String] = [:]
            for (key, value) in dict {
                serializable[key.rawValue] = "\(value)"
            }
            return serializable
        }
        UserDefaults.standard.set(data, forKey: "claude_cookies")
    }

    private func loadCookies() {
        guard let data = UserDefaults.standard.array(forKey: "claude_cookies") as? [[String: String]] else { return }
        var loaded = false
        for dict in data {
            let properties = Dictionary(uniqueKeysWithValues: dict.map {
                (HTTPCookiePropertyKey($0.key), $0.value as Any)
            })
            if let cookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(cookie)
                loaded = true
            }
        }
        isLoggedIn = loaded
    }

    private func clearCookies() {
        UserDefaults.standard.removeObject(forKey: "claude_cookies")
        if let url = URL(string: "https://claude.ai"),
           let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }

    // MARK: - Data Fetching

    func refresh() async {
        guard isLoggedIn else { return }
        isLoading = true
        error = nil

        do {
            let usage = try await ClaudeAPI.shared.fetchUsage()
            if let v = usage.sessionUtilization {
                sessionUtilization = v
                sessionResetsAt = usage.sessionResetsAt
            }
            if let v = usage.weeklyUtilization {
                weeklyUtilization = v
                weeklyResetsAt = usage.weeklyResetsAt
            }
            weeklySonnetUtilization = usage.weeklySonnetUtilization
            weeklySonnetResetsAt = usage.weeklySonnetResetsAt
            lastUpdated = Date()
            recordHistory()
            checkAndNotify()
            writeToSharedDefaults()
        } catch is ClaudeAPIError {
            isLoggedIn = false
            clearCookies()
            self.error = String(localized: "login.expired")
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Models

struct UsageRecord: Codable, Identifiable {
    let date: Date
    let session: Double
    let weekly: Double
    var id: Date { date }
}

enum UsageLevel {
    case normal, warning, danger, critical

    static func from(_ utilization: Double) -> UsageLevel {
        switch utilization {
        case ..<0.5: return .normal
        case ..<0.75: return .warning
        case ..<0.9: return .danger
        default: return .critical
        }
    }
}
