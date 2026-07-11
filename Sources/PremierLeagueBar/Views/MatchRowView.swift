import SwiftUI

struct MatchRowView: View {
    let match: Match
    @EnvironmentObject var viewModel: MatchViewModel

    var isPinned: Bool { viewModel.pinnedMatchId == match.id }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                TeamSection(team: match.homeTeam, alignment: .leading)
                ScoreSection(match: match)
                TeamSection(team: match.awayTeam, alignment: .trailing)
            }

            HStack(spacing: 4) {
                if match.isLive {
                    LiveBadge()
                }
                Text(match.dateFormatted)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { viewModel.togglePin(match.id) }) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .font(.caption2)
                        .foregroundColor(isPinned ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help(isPinned ? "Unpin from menu bar" : "Pin to menu bar")
                Text(match.statusDisplay)
                    .font(.caption2)
                    .fontWeight(match.isLive ? .bold : .regular)
                    .foregroundColor(match.isLive ? .red : .secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 6)
    }
}

struct TeamSection: View {
    let team: Match.Team
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(spacing: 6) {
            crestView
                .frame(width: 40, height: 40)
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(team.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var crestView: some View {
        if let url = team.crest.flatMap({ URL(string: $0) }) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().padding(4)
                case .failure:
                    placeholderCrest
                case .empty:
                    ProgressView().scaleEffect(0.5)
                @unknown default:
                    placeholderCrest
                }
            }
        } else {
            placeholderCrest
        }
    }

    private var placeholderCrest: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.15))
            .overlay(
                Text(team.displayName.prefix(1))
                    .font(.caption)
                    .foregroundColor(.secondary)
            )
    }
}

struct ScoreSection: View {
    let match: Match

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                if let home = match.score.fullTime?.home, let away = match.score.fullTime?.away {
                    Text("\(home)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(match.isLive ? .primary : .primary)
                    Text(":")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text("\(away)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(match.isLive ? .primary : .primary)
                } else {
                    Text("–")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(":")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text("–")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(match.isLive ? Color.red.opacity(0.08) : Color.clear)
        .cornerRadius(10)
    }
}

struct LiveBadge: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
                .opacity(animate ? 1 : 0.3)
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
