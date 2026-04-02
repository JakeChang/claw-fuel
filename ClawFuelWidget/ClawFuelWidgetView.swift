import SwiftUI
import WidgetKit

struct ClawFuelWidgetView: View {
    let entry: UsageEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.isLoggedIn {
            notLoggedInView
        } else {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
    }

    // MARK: - Small Widget (Session only)

    private var smallView: some View {
        VStack(spacing: 4) {
            UsageRing(
                utilization: entry.sessionUtilization,
                size: 88,
                lineWidth: 7
            )
            Text("Session")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            if let resetsAt = entry.sessionResetsAt {
                Text(shortReset(resetsAt))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Medium Widget (All three)

    private var mediumView: some View {
        HStack(spacing: 8) {
            ringColumn(
                title: "Session",
                utilization: entry.sessionUtilization,
                resetsAt: entry.sessionResetsAt
            )
            Divider().frame(height: 80)
            ringColumn(
                title: "Weekly",
                utilization: entry.weeklyUtilization,
                resetsAt: entry.weeklyResetsAt
            )
            Divider().frame(height: 80)
            ringColumn(
                title: "Sonnet",
                utilization: entry.weeklySonnetUtilization ?? 0,
                resetsAt: nil
            )
        }
    }

    private func ringColumn(title: String, utilization: Double, resetsAt: Date?) -> some View {
        VStack(spacing: 3) {
            UsageRing(
                utilization: utilization,
                size: 62,
                lineWidth: 5.5
            )
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(resetsAt.map { shortReset($0) } ?? " ")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Not Logged In

    private var notLoggedInView: some View {
        VStack(spacing: 8) {
            Image(systemName: "fuelpump.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(String(localized: "widget.not.logged.in"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private func shortReset(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval <= 0 { return String(localized: "reset.soon") }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours >= 24 {
            return String(format: String(localized: "reset.in.dhm"), hours / 24, hours % 24)
        } else if hours > 0 {
            return String(format: String(localized: "reset.in.hm"), hours, minutes)
        } else {
            return String(format: String(localized: "reset.in.m"), minutes)
        }
    }
}

// MARK: - Usage Ring

struct UsageRing: View {
    let utilization: Double
    let size: CGFloat
    let lineWidth: CGFloat

    private var remaining: Double { max(min(1.0 - utilization, 1.0), 0.0) }
    private var percentage: Int { Int(remaining * 100) }

    private var color: Color {
        switch remaining {
        case ..<0.1: return .red
        case ..<0.25: return Color(red: 0.9, green: 0.3, blue: 0.1)
        case ..<0.5: return .orange
        default: return .green
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: remaining)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(percentage)%")
                .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: size, height: size)
    }
}
