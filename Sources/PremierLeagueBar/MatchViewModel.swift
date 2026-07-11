import Foundation

@MainActor
class MatchViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var standings: [StandingEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshed: Date?

    private let api = APIService.shared
    private var refreshTask: Task<Void, Never>?

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    @Published var pollingPaused = false

    func startPolling() {
        pollingPaused = false
        refreshTask?.cancel()
        refreshTask = Task {
            await refresh()
            while !Task.isCancelled {
                guard let interval = nextPollInterval else {
                    pollingPaused = true
                    break
                }
                try? await Task.sleep(nanoseconds: interval)
                await refresh()
            }
        }
    }

    func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private var nextPollInterval: UInt64? {
        if hasLiveMatches {
            return 15_000_000_000
        }
        let now = Date()
        let twoHours: TimeInterval = 7200
        for match in upcomingMatches {
            if let date = isoFormatter.date(from: match.utcDate) {
                let timeUntil = date.timeIntervalSince(now)
                if timeUntil > 0 && timeUntil <= twoHours {
                    return 300_000_000_000
                }
            }
        }
        return nil
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            async let matchesTask = api.fetchMatches()
            async let standingsTask = api.fetchStandings()
            let (fetchedMatches, fetchedStandings) = await (try matchesTask, try standingsTask)
            matches = fetchedMatches
            standings = fetchedStandings
            lastRefreshed = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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

    var hasLiveMatches: Bool {
        !liveMatches.isEmpty
    }

    var liveMatchCount: Int {
        liveMatches.count
    }

    @Published var pinnedMatchId: Int?

    var pinnedMatch: Match? {
        guard let id = pinnedMatchId else { return nil }
        return matches.first { $0.id == id }
    }

    func togglePin(_ matchId: Int) {
        if pinnedMatchId == matchId {
            pinnedMatchId = nil
        } else {
            pinnedMatchId = matchId
        }
    }

    var menuBarLabel: String {
        if let pinned = pinnedMatch {
            let home = pinned.homeTeam.displayName
            let away = pinned.awayTeam.displayName
            if let h = pinned.score.fullTime?.home, let a = pinned.score.fullTime?.away {
                return "\(home) \(h)-\(a) \(away)"
            }
            return "\(home) vs \(away)"
        }
        if hasLiveMatches {
            return "\(liveMatchCount) LIVE"
        }
        return "PL"
    }
}
