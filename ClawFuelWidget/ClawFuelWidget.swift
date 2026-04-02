import WidgetKit
import SwiftUI

struct UsageEntry: TimelineEntry {
    let date: Date
    let sessionUtilization: Double
    let weeklyUtilization: Double
    let weeklySonnetUtilization: Double?
    let sessionResetsAt: Date?
    let weeklyResetsAt: Date?
    let isLoggedIn: Bool

    static let placeholder = UsageEntry(
        date: Date(),
        sessionUtilization: 0.3,
        weeklyUtilization: 0.2,
        weeklySonnetUtilization: 0.0,
        sessionResetsAt: Date().addingTimeInterval(3600),
        weeklyResetsAt: Date().addingTimeInterval(86400),
        isLoggedIn: true
    )
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(readEntry() ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let entry = readEntry() ?? UsageEntry(
            date: Date(),
            sessionUtilization: 0,
            weeklyUtilization: 0,
            weeklySonnetUtilization: nil,
            sessionResetsAt: nil,
            weeklyResetsAt: nil,
            isLoggedIn: false
        )
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readEntry() -> UsageEntry? {
        guard let usage = AppGroupConstants.read() else { return nil }

        return UsageEntry(
            date: Date(),
            sessionUtilization: usage.sessionUtilization,
            weeklyUtilization: usage.weeklyUtilization,
            weeklySonnetUtilization: usage.weeklySonnetUtilization,
            sessionResetsAt: usage.sessionResetsAt,
            weeklyResetsAt: usage.weeklyResetsAt,
            isLoggedIn: usage.isLoggedIn
        )
    }
}

struct ClawFuelWidget: Widget {
    let kind: String = "ClawFuelWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClawFuelWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(String(localized: "widget.title"))
        .description(String(localized: "widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
