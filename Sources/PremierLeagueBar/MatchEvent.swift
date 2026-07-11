import Foundation

enum MatchEvent: Equatable {
    var isGoal: Bool {
        if case .goal = self { return true }
        return false
    }

    var goalTeam: GoalTeam {
        guard case .goal(let team) = self else { return .home }
        return team
    }
    case goal(team: GoalTeam)
    case kickoff
    case halftime
    case secondHalfStarted
    case fulltime
    case matchPinned
    case matchUnpinned

    // MARK: - Future events (require additional API data)
    //
    // These are NOT yet detectable from the current football-data.org
    // /v4/competitions/PL/matches endpoint. Each case includes a note
    // on what API field/endpoint would be needed.
    //
    //   // TODO: yellowCard — requires booking data: /v4/matches/{id}
    //   //   where match.homeTeam.bookings / match.awayTeam.bookings exists
    //   //
    //   // TODO: redCard — same as yellowCard
    //   //
    //   // TODO: substitution — requires /v4/matches/{id}
    //   //   with substitution events
    //   //
    //   // TODO: injury — requires injury-time data or event feed
    //   //
    //   // TODO: penaltyAwarded — requires penalty event data
    //   //
    //   // TODO: penaltyScored — requires goal type metadata
    //   //
    //   // TODO: penaltyMissed — requires goal type metadata
    //   //
    //   // TODO: ownGoal — requires goal scorer/team metadata
    //   //
    //   // TODO: assist — requires goal assist data (person endpoint)
    //   //
    //   // TODO: VARStarted — requires VAR event feed
    //   //
    //   // TODO: VARConfirmed — requires VAR event feed
    //   //
    //   // TODO: VARCancelled — requires VAR event feed
    //   //
    //   // TODO: corner — requires match statistics endpoint
    //   //
    //   // TODO: offside — requires match statistics endpoint
    //   //
    //   // TODO: foul — requires match statistics endpoint
    //   //
    //   // TODO: save — requires goalkeeper/player stats
    //   //
    //   // TODO: shotOnTarget — requires match statistics endpoint

    enum GoalTeam: Equatable {
        case home
        case away
    }
}

// MARK: - Pure Engine

enum MatchEventEngine {

    /// Detects events by comparing a previous and current match snapshot.
    ///
    /// - Parameters:
    ///   - old: The previous `Match` snapshot, or `nil` on first fetch.
    ///   - new: The current `Match` snapshot.
    /// - Returns: An ordered array of `MatchEvent`s that occurred since the last refresh.
    ///
    /// This function is **pure**:
    ///   - No SwiftUI
    ///   - No networking
    ///   - No DynamicNotchKit
    ///   - No side effects
    static func detect(from old: Match?, to new: Match) -> [MatchEvent] {
        guard let old else { return [] }

        var events: [MatchEvent] = []

        // --- Goals ---
        // Detect by comparing previous and current scores.
        // If multiple goals were scored between polls, emit one event per goal.

        let oldHome = old.score.fullTime?.home ?? 0
        let oldAway = old.score.fullTime?.away ?? 0
        let newHome = new.score.fullTime?.home ?? 0
        let newAway = new.score.fullTime?.away ?? 0

        for _ in 0..<(newHome - oldHome) { events.append(.goal(team: .home)) }
        for _ in 0..<(newAway - oldAway) { events.append(.goal(team: .away)) }

        // --- Status Transitions ---

        switch (old.status, new.status) {
        case ("SCHEDULED", "IN_PLAY"),
             ("TIMED", "IN_PLAY"):
            events.append(.kickoff)

        case ("IN_PLAY", "PAUSED"):
            events.append(.halftime)

        case ("PAUSED", "IN_PLAY"):
            events.append(.secondHalfStarted)

        case ("IN_PLAY", "FINISHED"),
             ("PAUSED", "FINISHED"):
            events.append(.fulltime)

        default:
            break
        }

        return events
    }

    /// Detects events by comparing full match snapshots.
    /// Returns events for the match matching the given ID.
    ///
    /// - Parameters:
    ///   - old: Previous `[Match]` snapshot (before refresh).
    ///   - new: Current `[Match]` snapshot (after refresh).
    ///   - id: The match ID to detect events for.
    /// - Returns: An ordered array of `MatchEvent`s for that match.
    static func detect(from old: [Match], to new: [Match], forMatchId id: Int) -> [MatchEvent] {
        let oldMatch = old.first { $0.id == id }
        let newMatch = new.first { $0.id == id }
        guard let newMatch else { return [] }
        return detect(from: oldMatch, to: newMatch)
    }
}
