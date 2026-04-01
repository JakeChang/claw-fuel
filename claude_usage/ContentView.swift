import SwiftUI
import Charts

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct UsagePopoverView: View {
    var viewModel: UsageViewModel
    @Environment(\.openWindow) private var openWindow
    @State private var showSettings = false
    @State private var contentHeight: CGFloat = 0
    @State private var maxScrollHeight: CGFloat = 600

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "c.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
                Text(String(localized: "app.title"))
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else if viewModel.isLoggedIn {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            if !viewModel.isLoggedIn {
                loginPrompt
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                ScrollView {
                    usageContent
                        .padding(.bottom, 4)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                            }
                        )
                }
                .frame(height: min(contentHeight, maxScrollHeight))
                .onPreferenceChange(ContentHeightKey.self) { h in
                    contentHeight = h
                }
                .onAppear { updateMaxHeight() }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                    updateMaxHeight()
                }
            }

            Divider()
            footer
        }
        .frame(width: 300)
    }

    private func updateMaxHeight() {
        let screen = NSApp.keyWindow?.screen ?? NSScreen.main
        let h = screen?.visibleFrame.height ?? 800
        maxScrollHeight = h - 100
    }

    private var usageContent: some View {
        VStack(spacing: 8) {
            UsageCard(
                icon: "bolt.fill",
                title: String(localized: "session"),
                subtitle: String(localized: "session.window"),
                utilization: viewModel.sessionUtilization,
                resetsAt: viewModel.sessionResetsAt,
                showRemaining: viewModel.showRemaining
            )
            UsageCard(
                icon: "calendar",
                title: String(localized: "weekly"),
                subtitle: String(localized: "weekly.window"),
                utilization: viewModel.weeklyUtilization,
                resetsAt: viewModel.weeklyResetsAt,
                showRemaining: viewModel.showRemaining
            )
            if let sonnet = viewModel.weeklySonnetUtilization {
                UsageCard(
                    icon: "sparkles",
                    title: String(localized: "sonnet"),
                    subtitle: String(localized: "weekly.window"),
                    utilization: sonnet,
                    resetsAt: viewModel.weeklySonnetResetsAt,
                    showRemaining: viewModel.showRemaining
                )
            }

            ProjectionChartView(
                history: viewModel.usageHistory,
                sessionResetsAt: viewModel.sessionResetsAt,
                weeklyResetsAt: viewModel.weeklyResetsAt
            )

            UsageChartView(history: viewModel.usageHistory)

            HourlyUsageView(history: viewModel.usageHistory)
        }
        .padding(.horizontal, 16)
    }

    private var loginPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text(String(localized: "login.prompt"))
                .font(.callout)
                .foregroundStyle(.secondary)
            Button(String(localized: "login.connect")) {
                openWindow(id: "login")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(String(localized: "login.reconnect")) {
                openWindow(id: "login")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var footer: some View {
        HStack {
            if let lastUpdated = viewModel.lastUpdated {
                Text(lastUpdated.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings.toggle()
                }
            } label: {
                Image(systemName: showSettings ? "xmark.circle.fill" : "gearshape")
                    .font(.caption)
                    .foregroundStyle(showSettings ? .primary : .secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            if showSettings {
                settingsPanel
                    .offset(y: -36)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var settingsPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 10))
                Text(String(localized: "settings.title"))
                    .font(.caption.weight(.semibold))
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")(\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 10)

            // Toggles
            VStack(spacing: 0) {
                Toggle(isOn: Bindable(viewModel).showRemaining) {
                    HStack(spacing: 6) {
                        Image(systemName: "fuelpump")
                            .font(.system(size: 10))
                            .frame(width: 16)
                            .foregroundStyle(.purple)
                        Text(String(localized: "show.remaining"))
                            .font(.callout)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

                Divider()
                    .padding(.horizontal, 10)

                Toggle(isOn: Bindable(viewModel).launchAtLogin) {
                    HStack(spacing: 6) {
                        Image(systemName: "sunrise")
                            .font(.system(size: 10))
                            .frame(width: 16)
                            .foregroundStyle(.orange)
                        Text(String(localized: "launch.at.login"))
                            .font(.callout)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }

            Divider()
                .padding(.horizontal, 10)

            // Actions
            HStack(spacing: 0) {
                if viewModel.isLoggedIn {
                    Button {
                        viewModel.logout()
                        withAnimation { showSettings = false }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 9))
                            Text(String(localized: "logout"))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderless)

                    Divider()
                        .frame(height: 16)
                }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 9))
                        Text(String(localized: "quit"))
                            .font(.caption)
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderless)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thickMaterial)
                .shadow(color: .black.opacity(0.18), radius: 12, y: -3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 10)
    }
}

// MARK: - Usage Card

struct UsageCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let utilization: Double
    let resetsAt: Date?
    var showRemaining: Bool = false

    private var displayValue: Double { showRemaining ? (1.0 - utilization) : utilization }
    private var percentage: Int { Int(displayValue * 100) }
    private var level: UsageLevel { UsageLevel.from(utilization) }

    private var barColor: Color {
        switch level {
        case .normal: return Color(nsColor: .systemGreen)
        case .warning: return Color(nsColor: .systemOrange)
        case .danger: return Color(red: 0.9, green: 0.3, blue: 0.1)
        case .critical: return Color(nsColor: .systemRed)
        }
    }

    private var fuelColor: Color {
        let remaining = 1.0 - utilization
        switch remaining {
        case ..<0.1: return Color(nsColor: .systemRed)
        case ..<0.25: return Color(red: 0.9, green: 0.3, blue: 0.1)
        case ..<0.5: return Color(nsColor: .systemOrange)
        default: return Color(nsColor: .systemGreen)
        }
    }

    var body: some View {
        Group {
            if showRemaining {
                fuelGaugeLayout
            } else {
                barLayout
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(cardBackground)
        .overlay(cardBorder)
    }

    // MARK: - Bar Layout (used %)

    private var barLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 14)
                Text(title)
                    .font(.callout.weight(.medium))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("\(percentage)%")
                    .font(.system(.title3, design: .rounded).monospacedDigit().bold())
                    .foregroundStyle(barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(Color.primary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.8), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * min(utilization, 1.0), 0))
                }
            }
            .frame(height: 7)

            if let resetsAt {
                HStack(spacing: 3) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 8))
                    Text(formattedReset(resetsAt))
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Fuel Gauge Layout (remaining %)

    private var fuelGaugeLayout: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption.weight(.medium))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if let resetsAt {
                    HStack(spacing: 2) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 7))
                        Text(formattedReset(resetsAt))
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            FuelGaugeArc(value: displayValue, color: fuelColor, percentage: percentage)
                .frame(height: 52)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.background)
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
    }

    private func formattedReset(_ date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)
        if interval <= 0 { return String(localized: "reset.soon") }

        let isToday = Calendar.current.isDate(date, inSameDayAs: now)
        let timeStr: String
        if isToday {
            timeStr = date.formatted(date: .omitted, time: .shortened)
        } else {
            timeStr = date.formatted(.dateTime.month(.defaultDigits).day().hour().minute())
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let remaining: String
        if hours >= 24 {
            remaining = String(format: String(localized: "reset.in.dhm"), hours / 24, hours % 24)
        } else if hours > 0 {
            remaining = String(format: String(localized: "reset.in.hm"), hours, minutes)
        } else {
            remaining = String(format: String(localized: "reset.in.m"), minutes)
        }
        let suffix = String(localized: "reset.suffix")
        return "\(timeStr)（\(remaining) \(suffix)）"
    }
}

// MARK: - Fuel Gauge Arc

struct FuelGaugeArc: View {
    let value: Double
    let color: Color
    let percentage: Int

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r: CGFloat = h - 8
            let center = CGPoint(x: geo.size.width / 2, y: h - 2)
            let lw: CGFloat = 6

            ZStack {
                // Background arc
                Path { p in
                    p.addArc(center: center, radius: r,
                             startAngle: .degrees(180), endAngle: .degrees(0),
                             clockwise: false)
                }
                .stroke(Color.primary.opacity(0.1),
                        style: StrokeStyle(lineWidth: lw, lineCap: .round))

                // Fill arc (E=left → F=right)
                Path { p in
                    p.addArc(center: center, radius: r,
                             startAngle: .degrees(180),
                             endAngle: .degrees(180 + 180 * min(value, 1.0)),
                             clockwise: false)
                }
                .stroke(color.gradient,
                        style: StrokeStyle(lineWidth: lw, lineCap: .round))

                // Tick marks at 25%, 50%, 75%
                ForEach([0.25, 0.5, 0.75], id: \.self) { tick in
                    let a = Angle.degrees(180 + 180 * tick)
                    Path { p in
                        p.move(to: pt(center, r - lw / 2 - 1, a))
                        p.addLine(to: pt(center, r + lw / 2 + 1, a))
                    }
                    .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                }

                // Needle
                let na = Angle.degrees(180 + 180 * min(value, 1.0))
                Path { p in
                    p.move(to: center)
                    p.addLine(to: pt(center, r - lw / 2 - 3, na))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                Circle().fill(color).frame(width: 4, height: 4).position(center)

                // Percentage
                Text("\(percentage)%")
                    .font(.system(size: 12, design: .rounded).bold().monospacedDigit())
                    .foregroundStyle(color)
                    .position(x: center.x, y: center.y - r * 0.5)

                // E / F
                Text("E").font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundStyle(.red.opacity(0.4))
                    .position(x: center.x - r - lw - 3, y: center.y)
                Text("F").font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundStyle(.green.opacity(0.4))
                    .position(x: center.x + r + lw + 3, y: center.y)
            }
        }
    }

    private func pt(_ c: CGPoint, _ r: CGFloat, _ a: Angle) -> CGPoint {
        CGPoint(x: c.x + r * cos(CGFloat(a.radians)),
                y: c.y + r * sin(CGFloat(a.radians)))
    }
}

// MARK: - Usage Chart

struct UsageChartView: View {
    let history: [UsageRecord]

    @State private var selectedRange: ChartRange = .day

    enum ChartRange: String, CaseIterable {
        case day = "24h"
        case threeDays = "3d"
        case week = "7d"

        var interval: TimeInterval {
            switch self {
            case .day: return 24 * 3600
            case .threeDays: return 3 * 24 * 3600
            case .week: return 7 * 24 * 3600
            }
        }
    }

    private var filteredHistory: [UsageRecord] {
        let cutoff = Date().addingTimeInterval(-selectedRange.interval)
        return history.filter { $0.date > cutoff }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(localized: "trend.title"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $selectedRange) {
                    ForEach(ChartRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.mini)
                .frame(width: 120)
            }

            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Circle().fill(.purple).frame(width: 5, height: 5)
                    Text(String(localized: "session")).font(.system(size: 9)).foregroundStyle(.secondary)
                }
                HStack(spacing: 3) {
                    Circle().fill(.blue).frame(width: 5, height: 5)
                    Text(String(localized: "weekly")).font(.system(size: 9)).foregroundStyle(.secondary)
                }
                Spacer()
            }

            if filteredHistory.count >= 2 {
                Chart {
                    ForEach(filteredHistory) { record in
                        AreaMark(
                            x: .value("Time", record.date),
                            y: .value("Usage", record.session * 100),
                            series: .value("Type", "Session")
                        )
                        .foregroundStyle(.purple.opacity(0.12))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", record.date),
                            y: .value("Usage", record.session * 100),
                            series: .value("Type", "Session")
                        )
                        .foregroundStyle(.purple)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", record.date),
                            y: .value("Usage", record.weekly * 100),
                            series: .value("Type", "Weekly")
                        )
                        .foregroundStyle(.blue.opacity(0.08))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", record.date),
                            y: .value("Usage", record.weekly * 100),
                            series: .value("Type", "Weekly")
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }

                    RuleMark(y: .value("Warning", 90))
                        .foregroundStyle(.red.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 0.8, dash: [4, 3]))
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.primary.opacity(0.08))
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.primary.opacity(0.08))
                        AxisValueLabel(format: xAxisFormat)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 130)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "trend.collecting"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var xAxisFormat: Date.FormatStyle {
        switch selectedRange {
        case .day:
            return .dateTime.hour().minute()
        case .threeDays, .week:
            return .dateTime.month(.defaultDigits).day()
        }
    }
}

// MARK: - Projection View

struct ProjectionChartView: View {
    let history: [UsageRecord]
    let sessionResetsAt: Date?
    let weeklyResetsAt: Date?

    private var hasEnoughData: Bool {
        guard let first = history.first, let last = history.last else { return false }
        return last.date.timeIntervalSince(first.date) >= 1800
    }

    private func computeRate(_ keyPath: KeyPath<UsageRecord, Double>) -> Double? {
        guard hasEnoughData else { return nil }
        let sorted = history.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last, first.date != last.date else { return nil }
        let dt = last.date.timeIntervalSince(first.date) / 3600.0
        let dv = (last[keyPath: keyPath] - first[keyPath: keyPath]) * 100.0
        let rate = dv / dt
        return rate > 0.1 ? rate : nil
    }

    private func projected(current: Double, rate: Double?, resetAt: Date?) -> Int? {
        guard let rate, let resetAt else { return nil }
        let hours = max(resetAt.timeIntervalSince(Date()) / 3600.0, 0)
        return min(Int(current * 100.0 + rate * hours), 100)
    }

    private func remainingLabel(_ date: Date?) -> String {
        guard let date, date > Date() else { return String(localized: "reset.soon") }
        let interval = date.timeIntervalSince(Date())
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours >= 24 { return String(format: String(localized: "reset.in.dhm"), hours / 24, hours % 24) }
        if hours > 0 { return String(format: String(localized: "reset.in.hm"), hours, minutes) }
        return String(format: String(localized: "reset.in.m"), minutes)
    }

    var body: some View {
        let currentSession = history.last?.session ?? 0
        let currentWeekly = history.last?.weekly ?? 0
        let sessionRate = computeRate(\.session)
        let weeklyRate = computeRate(\.weekly)
        let sessionProjected = projected(current: currentSession, rate: sessionRate, resetAt: sessionResetsAt)
        let weeklyProjected = projected(current: currentWeekly, rate: weeklyRate, resetAt: weeklyResetsAt)

        VStack(spacing: 10) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(localized: "projection.title"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if !hasEnoughData {
                    Text(String(localized: "projection.collecting"))
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 10) {
                ProjectionGauge(
                    label: String(localized: "session"),
                    color: .purple,
                    current: Int(currentSession * 100),
                    projected: sessionProjected,
                    rate: sessionRate,
                    remaining: remainingLabel(sessionResetsAt)
                )
                ProjectionGauge(
                    label: String(localized: "weekly"),
                    color: .blue,
                    current: Int(currentWeekly * 100),
                    projected: weeklyProjected,
                    rate: weeklyRate,
                    remaining: remainingLabel(weeklyResetsAt)
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

struct ProjectionGauge: View {
    let label: String
    let color: Color
    let current: Int
    let projected: Int?
    let rate: Double?
    let remaining: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: CGFloat(current) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                if let projected, projected > current {
                    Circle()
                        .trim(from: CGFloat(current) / 100.0, to: CGFloat(projected) / 100.0)
                        .stroke(
                            projected >= 90 ? Color.red.opacity(0.5) : color.opacity(0.3),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [3, 3])
                        )
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 0) {
                    Text("\(current)%")
                        .font(.system(size: 14, design: .rounded).bold().monospacedDigit())
                        .foregroundStyle(color)
                    if let projected {
                        Text("→\(projected)%")
                            .font(.system(size: 9, design: .rounded).monospacedDigit())
                            .foregroundStyle(projected >= 90 ? .red : .secondary)
                    } else {
                        Text(String(localized: "projection.calculating"))
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(width: 60, height: 60)

            VStack(spacing: 2) {
                if let rate {
                    Text("\(String(format: "%.0f", rate))%/h")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 7))
                    Text(remaining)
                        .font(.system(size: 9))
                }
                .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - Hourly Usage Chart

struct HourlyUsageView: View {
    let history: [UsageRecord]

    struct HourlyBucket: Identifiable {
        let hour: Int
        let usage: Double
        var id: Int { hour }
        var label: String { String(format: "%02d", hour) }
    }

    private var hourlyData: [HourlyBucket] {
        var buckets = Array(repeating: 0.0, count: 24)
        let sorted = history.sorted { $0.date < $1.date }
        for i in 1..<sorted.count {
            let delta = (sorted[i].session - sorted[i - 1].session) * 100.0
            if delta > 0 {
                let hour = Calendar.current.component(.hour, from: sorted[i].date)
                buckets[hour] += delta
            }
        }
        return (0..<24).map { HourlyBucket(hour: $0, usage: buckets[$0]) }
    }

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(localized: "hourly.title"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(localized: "session"))
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }

            let hasData = hourlyData.contains { $0.usage > 0 }
            if hasData {
                Chart(hourlyData) { bucket in
                    BarMark(
                        x: .value("Hour", bucket.label),
                        y: .value("Usage", bucket.usage)
                    )
                    .foregroundStyle(
                        bucket.hour == currentHour
                            ? Color.purple
                            : bucket.usage > 0 ? Color.purple.opacity(0.5) : Color.primary.opacity(0.05)
                    )
                    .cornerRadius(2)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color.primary.opacity(0.08))
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)%")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: [0, 3, 6, 9, 12, 15, 18, 21].map { hourlyData[$0].label }) { _ in
                        AxisValueLabel()
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 100)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "trend.collecting"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
            }

            let peakHour = hourlyData.max(by: { $0.usage < $1.usage })
            let totalUsage = hourlyData.reduce(0) { $0 + $1.usage }
            if totalUsage > 0, let peak = peakHour, peak.usage > 0 {
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                        Text(String(format: String(localized: "hourly.peak"), String(format: "%02d", peak.hour)))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "sum")
                            .font(.system(size: 8))
                            .foregroundStyle(.purple)
                        Text(String(format: String(localized: "hourly.total"), String(format: "%.1f", totalUsage)))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}
