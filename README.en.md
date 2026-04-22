# Claw Fuel

A macOS menu bar app for real-time Claude AI usage monitoring.

[繁體中文](README.md)

![screen1](screen1.png)
![screen2](screen2.png)

## About

Claw Fuel is a macOS menu bar application that keeps you informed about your Claude AI API usage. With a clean menu bar icon and popover panel, you can monitor remaining quota, usage trends, and receive notifications before you run out.

## Features

- **Menu bar at a glance** — Icon and percentage with color-coded levels (green → orange → red)
- **Multi-window quota tracking** — Monitor Session (5-hour), Weekly (7-day), and Sonnet Weekly limits simultaneously
- **Trend charts** — Historical usage over 24h / 3d / 7d with area and line charts
- **Usage projection** — Estimates when your quota will be exhausted based on current rate
- **Hourly breakdown** — Bar chart showing per-hour usage with peak hour indicator
- **Smart notifications** — Alerts at 90% usage and reminders on quota reset
- **Launch at login** — Native macOS login item support
- **Auto-update** — Built-in Sparkle updater notifies you when a new version is available
- **Bilingual** — Full localization in Traditional Chinese and English

## Requirements

- macOS 15.0 or later
- Xcode 16 or later (for building)

## Getting Started

### Download (Recommended)

1. Go to [Releases](https://github.com/JakeChang/claw-fuel/releases) and download the latest `Claw-Fuel.dmg`
2. Open the DMG and drag `Claw-Fuel.app` into your Applications folder
3. **Before opening for the first time**, you must run the following command or macOS will block the app:
   - Open Terminal, paste the command below, and press Enter:
   ```bash
   xattr -cr /Applications/Claw-Fuel.app
   ```
4. Open the app, click the menu bar icon, and select "Connect Claude" to log in

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/JakeChang/claw-fuel.git
   ```
2. Open `claude_usage.xcodeproj` in Xcode
3. Build & Run (⌘R)
4. Click the Claw Fuel icon in the menu bar and select "Connect Claude" to log in
5. Once authenticated, usage tracking starts automatically

## How It Works

1. Authenticates with claude.ai via an embedded browser to obtain session cookies
2. Periodically (every 5 minutes) fetches the latest usage data from the Claude API
3. Parses utilization and reset times for Session / Weekly / Sonnet Weekly quotas
4. Stores usage history locally for trend charts and projection features

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | SwiftUI + MenuBarExtra |
| Charts | SwiftUI Charts |
| Auth | WebKit (WKWebView OAuth) |
| Notifications | UserNotifications |
| Launch at login | ServiceManagement |
| State management | @Observable (Observation framework) |
| Auto-update | Sparkle 2 |

## License

MIT
