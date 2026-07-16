import Foundation

struct MatchResponse: Codable {
    let matches: [Match]
}

struct StandingsResponse: Codable {
    let standings: [StandingTable]
}

struct StandingTable: Codable {
    let table: [StandingEntry]
}

struct StandingEntry: Codable, Identifiable {
    let position: Int
    let team: TeamInfo
    let playedGames: Int
    let won: Int
    let draw: Int
    let lost: Int
    let points: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int

    var id: String { "\(position)-\(team.name)" }
}

struct TeamInfo: Codable {
    let name: String
    let shortName: String?
    let tla: String?
    let crest: String?

    var displayName: String { tla ?? shortName ?? name }
}

struct Match: Codable, Identifiable {
    let id: Int
    let homeTeam: Team
    let awayTeam: Team
    let score: MatchScore
    let status: String
    let utcDate: String
    let stage: String?
    let matchday: Int?
    let minute: String?

    struct Team: Codable {
        let name: String
        let shortName: String?
        let tla: String?
        let crest: String?

        var displayName: String { tla ?? shortName ?? name }
        var shortDisplayName: String { shortName ?? tla ?? name }
    }

    struct MatchScore: Codable {
        let fullTime: ScoreDetail?
        let halfTime: ScoreDetail?
    }

    struct ScoreDetail: Codable {
        let home: Int?
        let away: Int?
    }

    var dateFormatted: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: utcDate) else { return utcDate }
        let display = DateFormatter()
        display.dateFormat = "E, MMM d  HH:mm"
        return display.string(from: date)
    }

    var statusDisplay: String {
        switch status {
        case "SCHEDULED": return "UPCOMING"
        case "TIMED": return "UPCOMING"
        case "IN_PLAY":
            if let m = minute, !m.isEmpty { return "\(m)'" }
            return "LIVE"
        case "PAUSED": return "HT"
        case "FINISHED": return "FT"
        case "CANCELLED": return "CANC"
        case "POSTPONED": return "POST"
        default: return status
        }
    }

    var isLive: Bool {
        status == "IN_PLAY" || status == "PAUSED"
    }

    var isFinished: Bool {
        status == "FINISHED"
    }
}
