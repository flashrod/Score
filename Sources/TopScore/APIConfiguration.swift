import Foundation

final class APIConfiguration: @unchecked Sendable {
    static let shared = APIConfiguration()

    let backendBaseURL: String

    private init() {
        backendBaseURL = "https://score.flashrod.deno.net"
    }
}
