<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-lightgrey" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-6.1-F05138?logo=swift" alt="Swift 6.1">
  <img src="https://img.shields.io/github/v/release/flashrod/Score" alt="Release">
  <img src="https://img.shields.io/github/downloads/flashrod/Score/total" alt="Downloads">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
</p>

<h1 align="center">Premier League Bar</h1>

<p align="center">
  Live Premier League scores in your macOS menu bar — no Xcode required.
</p>

<p align="center">
  <img src="https://github.com/flashrod/Score/releases/download/v1.0.1/PremierLeagueBar-1.0.1.dmg" alt="" width="1">
</p>

## Install

### Homebrew

```bash
brew tap flashrod/tap
brew trust flashrod/tap
brew install --cask premier-league-bar
```

> **First launch:** Go to **System Settings → Privacy & Security** → scroll down and click **Open Anyway**. This is needed once because the app is ad-hoc signed (no Apple Developer account).

### Manual

1. Download the latest `.dmg` from [releases](https://github.com/flashrod/Score/releases)
2. Mount the DMG and drag `PremierLeagueBar.app` to your Applications folder
3. **Bypass Gatekeeper** (first launch only — the app is ad-hoc signed, not notarized):

   **Option A:** Right-click `PremierLeagueBar.app` in Finder → **Open** → click **Open** in the dialog.

   **Option B:** Go to **System Settings → Privacy & Security** → scroll down and click **Open Anyway** next to the blocked app message.

   > *Only needed once. After registering the exception, the app will open normally.*
4. Launch the app

## Features

- **Menu bar icon** — pinned match score or live match count at a glance
- **Notch integration** — pinned match wraps around the notch using DynamicNotchKit
- **Live updates** — polls every 10s during matches, 3s during stoppage time
- **Goal celebrations** — notch expands with ⚽ GOAL + score animation
- **Match events** — kickoff, halftime, second half, full time — all detected automatically
- **Popover** — scrollable match list (live / upcoming / results) with standings table
- **Free-tier friendly** — stays under 10 req/min, pauses polling when idle

## Quick Start (from source)

```bash
git clone https://github.com/flashrod/Score.git
cd PremierLeagueBar
./build-and-run.sh
```

Builds a Swift 6.1 CLI app and launches it in your menu bar.

## How It Works

```
PollingPolicy ──→ MatchViewModel ←── MatchEventEngine
                       │
                ┌──────┴──────┐
                ↓              ↓
          EventQueue    DynamicNotchPresenter
                              ↓
                       DynamicNotch
                     (compact / expanded)
```

- **Single polling loop** fetches `/v4/competitions/PL/matches` once per cycle
- **MatchEventEngine** compares full snapshots to detect goals, status changes
- **EventQueue** FIFO-orders animations so events never overlap
- **DynamicNotchPresenter** animates each event sequentially (expand → show → collapse)

### Detected Events

| Event | Trigger |
|-------|---------|
| ⚽ Goal | Score increase between polls |
| 🏁 Kickoff | SCHEDULED/TIMED → IN_PLAY |
| ⏸️ Halftime | IN_PLAY → PAUSED |
| ▶️ Second Half | PAUSED → IN_PLAY |
| 🏆 Full Time | → FINISHED |

### Polling Intervals

| Match State | Interval |
|-------------|----------|
| Idle (no match pinned) | 60s |
| Before kickoff (< 15 min) | 30s |
| Before kickoff (< 5 min) | 15s |
| In play | 10s |
| Stoppage time (80-89 min) | 5s |
| Stoppage time (90+ min) | 3s |
| Half-time | 15s |
| Finished / Postponed / Cancelled | 60s / 5min |

## License

MIT
