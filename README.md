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
APIService (actor)
    ↕ fetches
MatchViewModel (ObservableObject)
    ├── match list + standings → ContentView (popover)
    ├── pinned match → presenter.show/update
    └── MatchEventEngine.detect(from:old, to:new) → [MatchEvent]
                                               ↓
                                          EventQueue
                                               ↓
                               DynamicNotchPresenter
                         (expand → show → wait → compact)
                                               ↓
                              DynamicNotch<Compact, Expanded>
```

Events flow through an `EventQueue` — the ViewModel posts detected events, and the `DynamicNotchPresenter` consumes them asynchronously, running sequenced expand-show-collapse animations. The ViewModel never calls animation methods directly.

**MatchEventEngine** is a pure function — no SwiftUI, no networking, no side effects. It compares two `Match` snapshots and returns detected events. Adding a new event type requires exactly 3 changes: the enum case, the detection logic, and the animation handling — nothing else.

Only the pinned match is compared, not all 380 returned matches.

## Events Detected

- Goal (home/away) — score increase between polls
- Kickoff — SCHEDULED/TIMED → IN_PLAY
- Halftime — IN_PLAY → PAUSED
- Second Half — PAUSED → IN_PLAY
- Full Time → FINISHED
- Match pinned/unpinned (local)

## License

MIT
