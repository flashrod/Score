import Foundation

@MainActor
final class EventQueue {
    typealias Handler = (MatchEvent) -> Void

    private var handler: Handler?
    private var buffer: [MatchEvent] = []

    func setHandler(_ handler: @escaping Handler) {
        self.handler = handler
        for event in buffer {
            handler(event)
        }
        buffer.removeAll()
    }

    func enqueue(_ event: MatchEvent) {
        if let handler {
            handler(event)
        } else {
            buffer.append(event)
        }
    }
}
