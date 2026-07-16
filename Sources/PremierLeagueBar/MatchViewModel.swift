@preconcurrency import Foundation
import AppKit

enum Tab: String, CaseIterable {
    case matches = "Matches"
    case standings = "Standings"
}

@MainActor
class MatchViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var standings: [StandingEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshed: Date?

    private let api = APIService.shared
    private var refreshTask: Task<Void, Never>?

    let eventQueue = EventQueue()
    private lazy var presenter = DynamicNotchPresenter(eventQueue: eventQueue)
    private let oddsStore = OddsStore()

    private var lastStandingsRefresh: Date?
    private var hasRefreshedStandingsOnce = false
    private var needsStandingsRefresh = false

    nonisolated(unsafe) private var testObserver: NSObjectProtocol?

    nonisolated(unsafe) static weak var shared: MatchViewModel?

    init() {
        Self.shared = self
        if ProcessInfo.processInfo.environment["DEBUG_ANIMATIONS"] != nil {
            setupTestEventObserver()
        }
    }

    private func setupTestEventObserver() {
        testObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.premierleaguebar.testEvent"),
            object: nil,
            queue: nil
        ) { notification in
            guard let raw = notification.object as? String else { return }
            let event: MatchEvent?
            switch raw {
            case "goal": event = .goal(team: .home)
            case "kickoff": event = .kickoff
            case "halftime": event = .halftime
            case "secondHalf": event = .secondHalfStarted
            case "fulltime": event = .fulltime
            default: event = nil
            }
            guard let event else { return }
            Task { @MainActor in
                MatchViewModel.shared?.eventQueue.enqueue(event)
            }
        }
    }

    func startPolling() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh()
                let interval = PollingPolicy.interval(for: pinnedMatch)
                try? await Task.sleep(nanoseconds: interval)
            }
        }
    }

    func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            let previousMatches = matches
            matches = try await api.fetchMatches()
            lastRefreshed = Date()

            if let pinned = pinnedMatch {
                let events = MatchEventEngine.detect(from: previousMatches, to: matches, forMatchId: pinned.id)
                let next = nextMatch(after: pinned.utcDate)
                presenter.update(match: pinned, nextMatch: next)
                for event in events {
                    if event.isGoal || event == .fulltime {
                        needsStandingsRefresh = true
                    }
                    eventQueue.enqueue(event)
                }
            }

            if shouldRefreshStandings {
                if let fetchedStandings = try? await api.fetchStandings() {
                    standings = fetchedStandings
                    lastStandingsRefresh = Date()
                    hasRefreshedStandingsOnce = true
                    needsStandingsRefresh = false
                }
            }

            if let pinned = pinnedMatch,
               pinned.status == "SCHEDULED" || pinned.status == "TIMED"
            {
                if oddsStore.shouldRefresh(for: pinned) {
                    await oddsStore.refresh()
                }
                if let odds = oddsStore.odds(for: pinned) {
                    presenter.homeWinPercent = odds.homeWinPercent
                    presenter.drawPercent = odds.drawPercent
                    presenter.awayWinPercent = odds.awayWinPercent
                }
            } else {
                presenter.homeWinPercent = nil
                presenter.drawPercent = nil
                presenter.awayWinPercent = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var shouldRefreshStandings: Bool {
        if !hasRefreshedStandingsOnce { return true }
        if needsStandingsRefresh { return true }
        guard let last = lastStandingsRefresh else { return true }
        if hasLiveMatches, Date().timeIntervalSince(last) > 60 { return true }
        return false
    }

    var liveMatches: [Match] {
        matches.filter { $0.isLive }.sorted { $0.utcDate < $1.utcDate }
    }

    var upcomingMatches: [Match] {
        matches.filter { !$0.isLive && !$0.isFinished }.sorted { $0.utcDate < $1.utcDate }
    }

    var finishedMatches: [Match] {
        matches.filter { $0.isFinished }.sorted { $0.utcDate > $1.utcDate }
    }

    var matchdayUpcoming: [Match] {
        upcomingMatches.filter { $0.matchday == currentMatchday }
    }

    var matchdayFinished: [Match] {
        finishedMatches.filter { $0.matchday == currentMatchday }
    }

    var hasLiveMatches: Bool {
        !liveMatches.isEmpty
    }

    var liveMatchCount: Int {
        liveMatches.count
    }

    @Published var selectedTab: Tab = .matches

    var currentMatchday: Int {
        if let live = liveMatches.first, let md = live.matchday { return md }
        if let upcoming = upcomingMatches.first, let md = upcoming.matchday { return md }
        return matches.compactMap(\.matchday).max() ?? 1
    }

    var displayedMatches: [Match] {
        let md = currentMatchday
        return matches.filter { $0.matchday == md || $0.isLive }
    }

    @Published var pinnedMatchId: Int?

    var pinnedMatch: Match? {
        guard let id = pinnedMatchId else { return nil }
        return matches.first { $0.id == id }
    }

    var debugMode: Bool {
        ProcessInfo.processInfo.environment["DEBUG_ANIMATIONS"] != nil
    }

    func testEvent(_ event: MatchEvent) {
        guard pinnedMatch != nil else { return }
        eventQueue.enqueue(event)
    }

    func togglePin(_ matchId: Int) {
        if pinnedMatchId == matchId {
            pinnedMatchId = nil
            presenter.hide()
            eventQueue.enqueue(.matchUnpinned)
        } else if let match = matches.first(where: { $0.id == matchId }) {
            pinnedMatchId = matchId
            let next = nextMatch(after: match.utcDate)
            presenter.show(match: match, nextMatch: next)
            eventQueue.enqueue(.matchPinned)
            if match.status == "SCHEDULED" || match.status == "TIMED" {
                // A newly pinned fixture must never briefly display the previous fixture's odds.
                presenter.homeWinPercent = nil
                presenter.drawPercent = nil
                presenter.awayWinPercent = nil
                if let odds = oddsStore.odds(for: match) {
                    presenter.homeWinPercent = odds.homeWinPercent
                    presenter.drawPercent = odds.drawPercent
                    presenter.awayWinPercent = odds.awayWinPercent
                } else {
                    Task { @MainActor in
                        await oddsStore.refresh()
                        if let odds = oddsStore.odds(for: match) {
                            presenter.homeWinPercent = odds.homeWinPercent
                            presenter.drawPercent = odds.drawPercent
                            presenter.awayWinPercent = odds.awayWinPercent
                        }
                    }
                }
            }
        }
    }

    private func nextMatch(after date: String) -> Match? {
        upcomingMatches.first { $0.utcDate > date }
    }

    var menuBarLabel: String {
        if let pinned = pinnedMatch {
            let home = pinned.homeTeam.shortDisplayName
            let away = pinned.awayTeam.shortDisplayName
            if let h = pinned.score.fullTime?.home, let a = pinned.score.fullTime?.away {
                if pinned.isLive, let m = pinned.minute, !m.isEmpty {
                    return "\(home) \(h)-\(a) \(away) \(m)'"
                }
                if pinned.isFinished {
                    return "\(home) \(h)-\(a) \(away) FT"
                }
                return "\(home) \(h)-\(a) \(away)"
            }
            if pinned.isLive { return "\(home) 0-0 \(away) 0'" }
            return "\(home) vs \(away)"
        }
        if hasLiveMatches {
            return "\(liveMatchCount) LIVE"
        }
        return "PL"
    }
}
