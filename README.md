# Premier League Bar

Live Premier League scores in your macOS menu bar, with a pinned match that wraps around the notch.

```
  ARS  1-1  COV  73'
 ┌──────────────────────┐
 │  1-1 · 73'          │
 │                     │
 │  [crest] [crest]    │
 └──────────────────────┘
```

Built entirely from the command line — no Xcode required.

## Features

- **Menu bar icon** shows pinned match score (or live match count)
- **Notch wrapping** — pinned match scores sit on either side of the notch using DynamicNotchKit
- **Live updates** — polls every 15s during matches (or 5min near kickoff)
- **Popover** — scrollable list of live/upcoming/results matches plus standings table
- **Pin any match** — click the dot on a match row to pin it to the notch
- **Goal animation** — the notch re-expands when a goal is scored
- **Status transitions** — detects kickoff, halftime, second half, full time
- **Free-tier friendly** — respects the 10 req/min API quota; stops polling when nothing is happening

## Requirements

- macOS 13+
- Swift 6.1 (Command Line Tools — no Xcode needed)
- [football-data.org](https://www.football-data.org/) API key (free tier)

## Setup

```bash
git clone https://github.com/flashrod/Score.git
cd PremierLeagueBar
export FOOTBALL_DATA_API_KEY=your_api_key_here
```

## Build & Run

```bash
./build-and-run.sh
```

This kills any running instance, builds the `.app` bundle, and launches it with your API key injected from the environment.

## Architecture

```
PollingPolicy (pure) ──────→ MatchViewModel ←── MatchEventEngine (pure)
                                     │
                            ┌────────┴────────┐
                            ↓                 ↓
                      EventQueue        presenter.show/update
                            │                 │
                            ↓                 ↓
                  DynamicNotchPresenter   DynamicNotch<Compact, Expanded>
```

**Refresh flow (single loop, one API request):**
1. Snapshot `matches` → `previousMatches`
2. Fetch `GET /v4/competitions/PL/matches` (single request)
3. Engine detects events by comparing full snapshots
4. Presenter updates pinned match data
5. Events posted to EventQueue for animation
6. `PollingPolicy.interval(for: pinnedMatch)` determines next wait

**MatchEventEngine** — pure function comparing full `[Match]` snapshots. No SwiftUI, no networking, no side effects. Adding a new event requires: enum case, detection logic, animation handling — nothing else.

**PollingPolicy** — pure interval logic based on match status and minute. Emits intervals from 3s (90+ min) to 5min (postponed/cancelled).

## Events Detected

- Goal (home/away) — score increase between polls
- Kickoff — SCHEDULED/TIMED → IN_PLAY
- Halftime — IN_PLAY → PAUSED
- Second Half — PAUSED → IN_PLAY
- Full Time → FINISHED
- Match pinned/unpinned (local)

## License

MIT
