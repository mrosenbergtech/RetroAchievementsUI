import SwiftUI
import Kingfisher

struct GameSummaryView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var gameID: Int
    
    // Controls the intentional delay for the skeleton transition
    @State private var showSkeleton: Bool = true
    
    var body: some View {
        Form {
            if let gameSummary = network.gameSummaryCache[gameID], !showSkeleton {
                // REAL CONTENT
                Group {
                    GameSummaryHeaderView(hardcoreMode: $hardcoreMode, gameID: gameID)
                    AchievementsView(hardcoreMode: $hardcoreMode, gameSummary: gameSummary)
                }
                .transition(.opacity)
            } else {
                // SKELETON CONTENT
                gameSummarySkeleton
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSkeleton)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Start the refresh timer
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds minimum skeleton time
            
            if network.gameSummaryCache[gameID] == nil {
                await network.getGameSummary(gameID: gameID)
            }
            
            // Allow data to show once both network is done AND timer is finished
            withAnimation {
                showSkeleton = false
            }
        }
        .refreshable {
            // Reset skeleton on manual pull-to-refresh
            showSkeleton = true
            await network.getGameSummary(gameID: gameID)
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation {
                showSkeleton = false
            }
        }
    }
    
    // MARK: - Skeleton Rows
    @ViewBuilder
    private var gameSummarySkeleton: some View {
        Section {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 64, height: 64)
                
                VStack(alignment: .center, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 15)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 12)
                    
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 10)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .frame(height: 4)
                    }
                    .padding(.horizontal)
                }
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
            }
            .padding(.vertical, 4)
        }
        
        Section(header: Text("Achievements")) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 160, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 220, height: 10)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .redacted(reason: .placeholder)
        .pulsing() // Custom modifier for shimmer effect
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    
    return NavigationView {
        GameSummaryView(hardcoreMode: $hardcoreMode, gameID: 10003)
            .environmentObject(network)
    }
}
