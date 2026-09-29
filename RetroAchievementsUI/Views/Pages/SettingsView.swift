//
//  SettingsView.swift
//  RetroAchievementsUI
//

import SwiftUI
import Kingfisher

struct SettingsView: View {
    @EnvironmentObject var network: Network
    @Binding var webAPIUsername: String
    @Binding var webAPIKey: String
    @Binding var hardcoreMode: Bool
    @Binding var showUnofficial: Bool
    @Binding var shouldShowLoginSheet: Bool

    @State private var showingLogoutAlert = false
    @State private var showCacheClearedToast = false
    @EnvironmentObject var tips: TipStore

    /// Settings is presented as a sheet from the profile header, not as a tab.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // This screen had no navigation container at all, so its
        // .navigationTitle never rendered.
        NavigationStack {
            Form {
                accountSection
                preferencesSection
                dataSection
                tipSection

                Section("About") {
                    Link(destination: URL(string: "https://retroachievements.org")!) {
                        Label("Visit RetroAchievements.org", systemImage: "safari")
                    }
                    LabeledContent("Version", value: Self.appVersion)
                        .font(.raBody)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.raSurface)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    webAPIUsername = ""
                    webAPIKey = ""     // Binding clears the Keychain item too.
                    network.logout()
                    // Dismiss first so ContentView can raise the login sheet;
                    // two sheets cannot be presented from the same place.
                    dismiss()
                }
            } message: {
                Text("You will need your Web API key to sign back in.")
            }
            .toast(isShowing: $showCacheClearedToast, message: "Image cache cleared")
            .toast(isShowing: $tips.justTipped, message: "Thank you!", systemImage: "heart.fill")
            .alert("Tip", isPresented: Binding(get: { tips.failureMessage != nil },
                                               set: { if !$0 { tips.failureMessage = nil } })) {
                Button("OK", role: .cancel) { tips.failureMessage = nil }
            } message: {
                Text(tips.failureMessage ?? "")
            }
            .task {
                tips.refreshFromCloud()
                await tips.loadProducts()
            }
        }
    }

    @ViewBuilder
    private var accountChips: some View {
        HStack(spacing: 6) {
            RAChip(text: network.webAPIAuthenticated ? "AUTHENTICATED" : "ACTION REQUIRED",
                   tint: network.webAPIAuthenticated ? .green : .red) {
                RAStatusDot()
            }

            if tips.hasTipped {
                // Icon only, matching the profile header: the word clipped to
                // "CONTRI" beside the account chip and the Log Out button.
                RAIconChip(systemImage: tips.badgeSymbol, tint: Color.raAccent,
                           accessibilityLabel: "Contributed")
            }
        }
    }

    // MARK: - Tips

    /// Absent entirely when StoreKit has no products to sell — an unreachable
    /// store, or a build whose products are not live yet. A row of dead tip
    /// buttons is worse than no tip jar.
    @ViewBuilder
    private var tipSection: some View {
        if !tips.products.isEmpty {
            Section {
                ForEach(tips.products) { product in
                    Button {
                        Task { await tips.purchase(product) }
                    } label: {
                        HStack {
                            Label(product.displayName, systemImage: product.symbolName)
                                .font(.raBody)
                                .foregroundStyle(Color.raTextPrimary)
                            Spacer(minLength: 8)
                            if tips.purchasing == product.id {
                                ProgressView().controlSize(.small)
                            } else {
                                // StoreKit's own formatting, so a reader
                                // outside the US sees their own currency.
                                Text(product.displayPrice)
                                    .font(.system(.subheadline, design: .monospaced)
                                        .weight(.semibold))
                                    .foregroundStyle(Color.raAccent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(tips.purchasing != nil)
                }
            } header: {
                Text("Tip Jar")
            }
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section {
            HStack(spacing: 14) {
                KFImage(RAImageURL.avatar(network.profile?.userPic))
                    .resizable()
                    .placeholder { Circle().fill(Color.raSurfaceSunken) }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(network.webAPIAuthenticated
                         ? network.authenticatedWebAPIUsername
                         : "Not Signed In")
                        .font(.raTitle)
                        .foregroundStyle(Color.raTextPrimary)
                        .lineLimit(1)

                    // Two chips and a Log Out button share this row, so they
                    // scroll horizontally rather than compressing into
                    // hyphenless wraps on a narrow phone or at large type.
                    ViewThatFits(in: .horizontal) {
                        accountChips
                        ScrollView(.horizontal) {
                            accountChips
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                Spacer(minLength: 0)

                if network.webAPIAuthenticated {
                    Button("Log Out") { showingLogoutAlert = true }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                } else {
                    Button("Log In") { shouldShowLoginSheet = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.raAccent)
                        .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Account")
        } footer: {
            if network.webAPIAuthenticated {
                Text("Your API key is stored in the Keychain and synced via iCloud Keychain.")
            } else {
                Text("Enter your credentials to access your achievements and progress.")
            }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $hardcoreMode) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hardcore Mode")
                        Text("Show only hardcore points, progress and awards")
                            .font(.raCaption)
                            .foregroundStyle(Color.raTextSecondary)
                    }
                } icon: {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                }
            }

            Toggle(isOn: $showUnofficial) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include Unofficial Games")
                        Text("Show demo and prototype sets marked with ~")
                            .font(.raCaption)
                            .foregroundStyle(Color.raTextSecondary)
                    }
                } icon: {
                    Image(systemName: "wrench.and.screwdriver.fill").foregroundStyle(.purple)
                }
            }
        } header: {
            Text("Preferences")
        }
        .tint(.raAccent)
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Button {
                let cache = ImageCache.default
                cache.clearMemoryCache()
                cache.clearDiskCache {
                    withAnimation { showCacheClearedToast = true }
                }
            } label: {
                Label("Clear Image Cache", systemImage: "photo.on.rectangle.angled")
            }

            if network.isFetchingFullGameList {
                HStack {
                    Label("Syncing Game List…", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text("\(Int(network.syncProgressPercentage))%")
                        .font(.raStatSmall)
                        .foregroundStyle(Color.raTextTertiary)
                }
            } else {
                Button {
                    Task { await network.refreshGameList() }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("Refresh Game List", systemImage: "arrow.clockwise")
                        if let lastSynced = network.gameListLastSynced {
                            Text("Last synced \(lastSynced.formatted(date: .abbreviated, time: .shortened))")
                                .font(.raCaption)
                                .foregroundStyle(Color.raTextSecondary)
                        }
                    }
                }
            }
        } header: {
            Text("Data")
        } footer: {
            Text("The game list is cached on device for a week and refreshed automatically.")
        }
    }

    /// Marketing version only — the build number is noise for users.
    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

#Preview {
    @Previewable @State var webAPIUsername = debugWebAPIUsername
    @Previewable @State var webAPIKey = debugWebAPIKey
    @Previewable @State var hardcoreMode = true
    @Previewable @State var showUnofficial = false
    @Previewable @State var shouldShowLoginSheet = false

    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    return SettingsView(webAPIUsername: $webAPIUsername, webAPIKey: $webAPIKey,
                        hardcoreMode: $hardcoreMode, showUnofficial: $showUnofficial,
                        shouldShowLoginSheet: $shouldShowLoginSheet)
        .environmentObject(network)
        .environmentObject(TipStore())
}
