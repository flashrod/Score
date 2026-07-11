import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MatchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.matches.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }

                if let error = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }

                if !viewModel.hasLiveMatches && viewModel.upcomingMatches.isEmpty && viewModel.finishedMatches.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                    VStack(spacing: 8) {
                        Text("No matches yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("The Premier League season starts in August")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }

                if viewModel.hasLiveMatches {
                    HStack {
                        LiveIndicator()
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)

                    ForEach(viewModel.liveMatches) { match in
                        MatchRowView(match: match)
                            .padding(.horizontal)
                        Divider().opacity(0.3).padding(.horizontal)
                    }
                }

                if !viewModel.upcomingMatches.isEmpty {
                    sectionHeader("UPCOMING")
                    ForEach(Array(viewModel.upcomingMatches.prefix(5))) { match in
                        MatchRowView(match: match)
                            .padding(.horizontal)
                        Divider().opacity(0.3).padding(.horizontal)
                    }
                }

                if !viewModel.finishedMatches.isEmpty {
                    sectionHeader("RECENT RESULTS")
                    ForEach(Array(viewModel.finishedMatches.prefix(5))) { match in
                        MatchRowView(match: match)
                            .padding(.horizontal)
                        Divider().opacity(0.3).padding(.horizontal)
                    }
                }

                if !viewModel.standings.isEmpty {
                    sectionHeader("")
                    StandingsView(standings: viewModel.standings)
                }

                if let lastRefreshed = viewModel.lastRefreshed {
                    Text("Updated \(lastRefreshed.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)
                }
            }
            .padding(.vertical)
        }
        .frame(width: 340, height: 500)
    }

    private var header: some View {
        HStack {
            Image(systemName: "soccerball")
                .foregroundColor(.green)
            Text("Premier League")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 30)
            }
            Button("Refresh") {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, text.isEmpty ? 0 : 4)
    }
}
