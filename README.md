# Claw Fuel

[English](#english) | [繁體中文](#繁體中文)

---

## English

> A macOS menu bar app for real-time Claude AI usage monitoring — track your quota, view trends, and get notified before you run out.

Built with **SwiftUI + MenuBarExtra**, a lightweight menu bar tool designed for Claude AI power users.

![screen1](screen1.png)
![screen2](screen2.png)

### Features

- **Menu Bar at a Glance** — Icon and percentage with color-coded levels (green → orange → red)
- **Multi-quota Tracking** — Monitor Session (5-hour), Weekly (7-day), and Sonnet Weekly limits simultaneously
- **Trend Charts** — Historical usage over 24h / 3d / 7d with area and line charts
- **Usage Projection** — Estimates when your quota will be exhausted based on current rate
- **Hourly Breakdown** — Bar chart showing per-hour usage with peak hour indicator
- **Smart Notifications** — Alerts at 90% usage and reminders on quota reset
- **Launch at Login** — Native macOS login item support
- **Auto Update** — Built-in Sparkle updater notifies you when a new version is available
- **Bilingual** — Full localization in Traditional Chinese and English

### Download

Go to [Releases](https://github.com/JakeChang/claw-fuel/releases/latest) to download the latest DMG.

Supports macOS 15+ / Apple Silicon & Intel.

On first launch, run:

```
xattr -cr /Applications/Claw-Fuel.app
```

### Setup

1. Open the app, click the menu bar icon, and select "Connect Claude" to log in
2. Once authenticated, usage tracking starts automatically

### Development

1. Clone the repo and open `claude_usage.xcodeproj` in Xcode
2. Select the **Claw Fuel** scheme and press `Cmd+R` to run

**Requirements:** Xcode 16+, macOS 15.0+, Swift 5.0

### License

MIT

---

## 繁體中文

> macOS 選單列 Claude AI 用量監控工具 — 即時追蹤額度、查看趨勢，額度即將用盡時自動通知。

基於 **SwiftUI + MenuBarExtra** 打造，專為 Claude AI 重度使用者設計的輕量選單列工具。

![screen1](screen1.png)
![screen2](screen2.png)

### 功能

- **選單列即時顯示** — 圖示與百分比一目瞭然，依使用量變色（綠 → 橘 → 紅）
- **多維度額度追蹤** — 同時監控 Session（5 小時）、Weekly（7 天）及 Sonnet Weekly 額度
- **趨勢圖表** — 24 小時 / 3 天 / 7 天歷史用量走勢，搭配面積圖與折線圖
- **用量預測** — 根據目前使用速率，推算額度耗盡時間
- **每小時用量分析** — 柱狀圖呈現每小時用量，標示尖峰時段
- **智慧通知** — 用量達 90% 時發出警告，額度重置時自動提醒
- **開機自動啟動** — 支援 macOS 原生「登入時啟動」
- **自動更新** — 內建 Sparkle 更新機制，有新版本時自動通知
- **雙語支援** — 繁體中文與英文完整在地化

### 下載

前往 [Releases](https://github.com/JakeChang/claw-fuel/releases/latest) 下載最新版 DMG。

支援 macOS 15+ / Apple Silicon & Intel。

首次安裝需執行：

```
xattr -cr /Applications/Claw-Fuel.app
```

### 設定

1. 開啟 App，在選單列點擊圖示，選「連接 Claude」進行登入
2. 登入成功後即自動開始追蹤用量

### 開發

1. Clone 專案後，用 Xcode 開啟 `claude_usage.xcodeproj`
2. 選擇 Scheme **Claw Fuel**，按 `Cmd+R` 即可執行

**需求：** Xcode 16+、macOS 15.0+、Swift 5.0

### License

MIT
