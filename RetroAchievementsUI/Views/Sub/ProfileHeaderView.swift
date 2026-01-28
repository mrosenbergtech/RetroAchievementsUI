import SwiftUI
import Kingfisher

struct ProfileHeaderView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    @State private var pulseAlpha: Double = 1.0

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 16) {
                // MARK: - Avatar
                ZStack {
                    // Ring now represents Online Status (Green = Online, Gray = Offline)
                    Circle()
                        .stroke(network.isUserOnline ? Color.green : Color.gray.opacity(0.5), lineWidth: 3)
                        .frame(width: 64, height: 64)
                        .shadow(color: network.isUserOnline ? .green.opacity(0.3) : .clear, radius: 4)
                        .opacity(network.isUserOnline ? pulseAlpha : 1.0) // Pulse effect when online

                    KFImage(URL(string: "https://retroachievements.org/" + (network.profile?.userPic ?? "UserPic/retroachievementsUI")))
                        .resizable()
                        .placeholder { Circle().fill(Color.gray.opacity(0.2)) }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseAlpha = 0.4
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(network.profile?.user ?? "Username")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                    
                    HStack(spacing: 6) {
                        // MARK: - Online/Offline Badge
                        HStack(spacing: 3) {
                            Circle()
                                .frame(width: 5, height: 5)
                            Text(network.isUserOnline ? "ONLINE" : "OFFLINE")
                                .font(.system(size: 8, weight: .black))
                        }
                        .foregroundStyle(network.isUserOnline ? .green : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(network.isUserOnline ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(4)

                        // MARK: - Labeled Hardcore Badge
                        HStack(spacing: 4) {
                            Image(systemName: hardcoreMode ? "trophy.circle.fill" : "bolt.circle.fill")
                                .font(.system(size: 11))
                            Text(hardcoreMode ? "HARDCORE" : "STANDARD")
                                .font(.system(size: 8, weight: .black))
                        }
                        .foregroundStyle(hardcoreMode ? .orange : .blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(hardcoreMode ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // MARK: - Quick Stats
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(hardcoreMode ? network.profile?.totalPoints ?? 0 : network.profile?.totalSoftcorePoints ?? 0)")
                        .font(.system(.headline, design: .monospaced))
                    Text("POINTS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // MARK: - Status Bar
            if !network.isFetching {
                ScrollingText(text: network.buildUserStatusMessage(),
                              font: .preferredFont(forTextStyle: .caption2),
                              leftFade: 10,
                              rightFade: 10,
                              startDelay: 3,
                              alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Helper Stat View
struct StatView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .bold()
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: "Sample", webAPIKey: "Sample")
    }
    return ProfileHeaderView(hardcoreMode: $hardcoreMode)
        .environmentObject(network)
}
