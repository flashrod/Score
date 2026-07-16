import Foundation

@MainActor
final class OddsStore {
    private let api = APIService.shared
    private var cache: [Odds] = []
    private var lastRefresh: Date?

    private static let isoFormatter = ISO8601DateFormatter()

    func odds(for match: Match) -> Odds? {
        cache.first { odds in
            (match.homeTeam.name == odds.homeTeam || match.homeTeam.name.contains(odds.homeTeam) || odds.homeTeam.contains(match.homeTeam.name))
            && (match.awayTeam.name == odds.awayTeam || match.awayTeam.name.contains(odds.awayTeam) || odds.awayTeam.contains(match.awayTeam.name))
        }
    }

    func shouldRefresh(for match: Match) -> Bool {
        guard match.status == "SCHEDULED" || match.status == "TIMED" else { return false }

        if odds(for: match) == nil { return true }

        if let last = lastRefresh, Date().timeIntervalSince(last) < 300 { return false }

        if let kickoff = Self.isoFormatter.date(from: match.utcDate) {
            let delta = kickoff.timeIntervalSinceNow
            if delta <= 0 { return false }
            if delta <= 1800 { return true }
        }

        return false
    }

    func refresh() async {
        do {
            cache = try await api.fetchOdds()
            lastRefresh = Date()
        } catch {
            // Silent — use cached data if available
        }
    }

    func clear() {
        cache.removeAll()
        lastRefresh = nil
    }
}
