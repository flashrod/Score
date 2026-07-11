import Cocoa
import SwiftUI

@MainActor
class NotchController {
    private var statusItem: NSStatusItem?

    func show(match: Match) {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(
                withLength: NSStatusItem.variableLength
            )
            statusItem?.button?.font = NSFont.monospacedDigitSystemFont(
                ofSize: 11,
                weight: .medium
            )
        }
        statusItem?.button?.title = menuTitle(for: match)
        statusItem?.isVisible = true
    }

    func hide() {
        statusItem?.isVisible = false
    }

    func update(match: Match) {
        statusItem?.button?.title = menuTitle(for: match)
    }

    private func menuTitle(for match: Match) -> String {
        let home = match.homeTeam.displayName
        let away = match.awayTeam.displayName
        if let h = match.score.fullTime?.home, let a = match.score.fullTime?.away {
            if match.isLive, let m = match.minute, !m.isEmpty {
                return "\(home) \(h)-\(a) \(away) \(m)'"
            }
            return "\(home) \(h)-\(a) \(away)"
        }
        return "\(home) vs \(away)"
    }
}
