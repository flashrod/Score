import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MatchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                if viewModel.debugMode {
                    debugRow
                        .padding(.horizontal, 12)
                }

                if viewModel.isLoading && viewModel.matches.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
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
                    .padding(.vertical, 30)
                }

                if !viewModel.hasLiveMatches && viewModel.upcomingMatches.isEmpty && viewModel.finishedMatches.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                    emptyState
                }

                if viewModel.hasLiveMatches {
                    sectionLabel("LIVE NOW")
                    liveBanner
                    ForEach(viewModel.liveMatches) { match in
                        matchCard(match)
                    }
                }

                if !viewModel.upcomingMatches.isEmpty {
                    sectionLabel("UPCOMING")
                    ForEach(Array(viewModel.upcomingMatches.prefix(4))) { match in
                        matchCard(match)
                    }
                }

                if !viewModel.finishedMatches.isEmpty {
                    sectionLabel("RESULTS")
                    ForEach(Array(viewModel.finishedMatches.prefix(4))) { match in
                        matchCard(match)
                    }
                }

                if !viewModel.standings.isEmpty {
                    sectionLabel("")
                    StandingsView(standings: viewModel.standings)
                }

                if let lastRefreshed = viewModel.lastRefreshed {
                    HStack(spacing: 4) {
                        Text("Updated \(lastRefreshed.formatted(date: .omitted, time: .shortened))")
                        if viewModel.pollingPaused {
                            Circle().fill(.orange).frame(width: 4, height: 4)
                            Text("auto-refresh paused")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 340, height: 500)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            Text("Premier League")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if let pinned = viewModel.pinnedMatch {
                Image(systemName: "pin.fill").font(.caption2).foregroundColor(.blue)
                Text("\(pinned.homeTeam.displayName) vs \(pinned.awayTeam.displayName)")
                    .font(.caption)
                    .foregroundColor(.blue)
                Button(action: { viewModel.togglePin(pinned.id) }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Unpin")
            }
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 20, height: 20)
            }
            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    private var debugRow: some View {
        VStack(spacing: 4) {
            Text("DEBUG ANIMATIONS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
            HStack(spacing: 6) {
                debugButton("Goal") { viewModel.testEvent(.goal(team: .home)) }
                debugButton("HT") { viewModel.testEvent(.halftime) }
                debugButton("2H") { viewModel.testEvent(.secondHalfStarted) }
                debugButton("FT") { viewModel.testEvent(.fulltime) }
            }
        }
        .padding(.vertical, 4)
    }

    private func debugButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("No matches scheduled")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Season starts 21 Aug 2026")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text("Auto-refresh paused. Tap Refresh for latest.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private var liveBanner: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
            Text("\(viewModel.liveMatchCount) match\(viewModel.liveMatchCount == 1 ? "" : "es") in play")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
    }

    private func matchCard(_ match: Match) -> some View {
        MatchRowView(match: match)
            .padding(.horizontal, 10)
            .background(Color(.windowBackgroundColor).opacity(0.3))
            .cornerRadius(10)
            .padding(.horizontal, 4)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, text.isEmpty ? 0 : 2)
    }
}
