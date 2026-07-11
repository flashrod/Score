import SwiftUI

@main
struct PremierLeagueBar: App {
    @StateObject private var viewModel = {
        let vm = MatchViewModel()
        vm.startPolling()
        return vm
    }()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
        } label: {
            Label(viewModel.menuBarLabel, systemImage: "soccerball")
        }
        .menuBarExtraStyle(.window)
    }
}
