import Foundation

enum PollingPolicy {

    /// Returns the next refresh interval in nanoseconds for the given match.
    ///
    /// - Parameter match: The currently pinned match, or `nil` if none is pinned.
    /// - Returns: Nanoseconds to wait before the next refresh.
    ///
    /// Pure logic — no networking, no timers, no side effects.
    static func interval(for match: Match?) -> UInt64 {
        guard let match else { return 60_000_000_000 }

        switch match.status {
        case "TIMED":
            return 60_000_000_000

        case "IN_PLAY":
            if let minuteStr = match.minute, let m = Int(minuteStr) {
                if m >= 90 { return 3_000_000_000 }
                if m >= 80 { return 5_000_000_000 }
            }
            return 10_000_000_000

        case "PAUSED":
            return 15_000_000_000

        case "FINISHED":
            return 60_000_000_000

        case "POSTPONED":
            return 300_000_000_000

        case "SUSPENDED":
            return 30_000_000_000

        case "CANCELLED":
            return 300_000_000_000

        default:
            return 60_000_000_000
        }
    }
}
