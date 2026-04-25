# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claw Fuel is a macOS menu bar app that monitors Claude AI usage quotas in real time. It tracks Session (5-hour), Weekly (7-day), and Sonnet Weekly limits with trend charts, usage projections, and smart notifications.

Built with SwiftUI + MenuBarExtra, targeting macOS 15.0+. Universal Binary (Apple Silicon & Intel).

## Build & Run

Open `claude_usage.xcodeproj` in Xcode 16+ and press `Cmd+R`. The scheme is `claude_usage`, which produces `Claw-Fuel.app`.

There are no test targets in this project.

## Architecture

Single-target macOS menu bar app using `@Observable` (Swift Observation framework), not `ObservableObject`.

### Core Files

- **`claude_usageApp.swift`** — Entry point. `MenuBarExtra` scene with Sparkle updater and an AppDelegate that prevents termination on window close.
- **`UsageViewModel.swift`** — Central state container. Handles auto-refresh (every 5 min), cookie/session persistence via UserDefaults, notification management (90% threshold + reset reminders), usage history (7-day rolling window in UserDefaults), and launch-at-login via `SMAppService`.
- **`ClaudeAPI.swift`** — Singleton API service. Two-step fetch: first `/api/organizations` to get org ID, then `/api/organizations/{id}/usage` for quota data. Handles both UUID and Int org IDs.
- **`ContentView.swift`** — All UI views in one file (~1039 lines): `UsagePopoverView`, `UsageCard`, `FuelGaugeArc`, `UsageChartView`, `ProjectionChartView`, `ProjectionGauge`, `HourlyUsageView`.
- **`LoginWebView.swift`** — WKWebView wrapper for OAuth login to claude.ai; detects session cookie on success.
- **`LoginWindowController.swift`** — Manages the login window lifecycle.

### Data Flow

1. User logs in via WKWebView → session cookie saved to HTTPCookieStorage + UserDefaults
2. `UsageViewModel.refresh()` calls `ClaudeAPI.fetchUsage()` (async/await)
3. Response parsed into `UsageData` (utilization percentages + reset dates per quota window)
4. ViewModel updates state → SwiftUI re-renders charts/gauges
5. History recorded as `UsageRecord` array in UserDefaults; notifications checked each cycle

### Key Types

- `UsageData` — API response model (utilization + reset times)
- `UsageRecord` — Codable historical snapshot for trend charts
- `UsageLevel` — Enum: normal / warning / danger / critical (drives color coding)
- `ClaudeAPIError` — Localized error types

## Localization

Bilingual: English (`en.lproj/Localizable.strings`) and Traditional Chinese (`zh-Hant.lproj/Localizable.strings`). All user-facing strings must use `NSLocalizedString`.

## CI/CD

GitHub Actions release pipeline (`.github/workflows/release.yml`) triggers on `v*.*.*` tags. Builds universal binary, creates DMG with `create-dmg`, signs with Sparkle EdDSA key, generates `appcast.xml`, and publishes to GitHub Releases + GitHub Pages.

## Dependencies

- **Sparkle 2.6.4** (SPM) — Auto-update framework with EdDSA signing
