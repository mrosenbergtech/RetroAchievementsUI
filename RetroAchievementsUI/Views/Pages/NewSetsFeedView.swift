//
//  NewSetsFeedView.swift
//  RetroAchievementsUI
//
//  What's being written: sets finished recently, and sets under way.
//
//  Built from development claims, because the API has no "a set was published"
//  event — a completed claim is the nearest thing to it. That is why the
//  heading says "Recently completed" rather than "New this week", and why an
//  in-progress claim is dated from when it was made rather than from its
//  DoneTime, which for an active claim is an expiry date.
//

import SwiftUI
import Kingfisher

struct NewSetsFeedView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    @State private var isLoading = true
    @State private var loadError: RANetworkError?
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case newSets = "New"
        case revisions = "Revisions"
        var id: String { rawValue }
    }

    private func matching(_ claims: [SetClaim]) -> [SetClaim] {
        switch filter {
        case .all: return claims
        case .newSets: return claims.filter { !$0.isRevision }
        case .revisions: return claims.filter(\.isRevision)
        }
    }

    private var completed: [SetClaim] { matching(network.completedSetClaims) }
    private var active: [SetClaim] { matching(network.activeSetClaims) }

    var body: some View {
        List {
            Section {
                Picker("", selection: $filter) {
                    ForEach(Filter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
            .listRowBackground(Color.clear)

            if !completed.isEmpty {
                Section {
                    ForEach(completed) { claim in row(claim) }
                } header: {
                    Text("Recently completed")
                }
                .listRowBackground(Color.raSurfaceRaised)
            }

            if !active.isEmpty {
                Section {
                    ForEach(active) { claim in row(claim) }
                } header: {
                    Text("In progress")
                } footer: {
                    Text("Claimed sets being written now. A claim can still be dropped.")
                }
                .listRowBackground(Color.raSurfaceRaised)
            }

            if completed.isEmpty && active.isEmpty && !isLoading {
                emptyState
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.raSurface)
        .overlay {
            if isLoading && !network.setClaimsLoaded { ProgressView() }
        }
        .refreshable { await load(force: true) }
        .task { await load(force: false) }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "hammer")
                .font(.system(size: 30))
                .foregroundStyle(Color.raTextTertiary)
            Text(loadError == nil ? "Nothing here yet" : "Couldn’t load the feed")
                .font(.raTitle)
                .foregroundStyle(Color.raTextPrimary)
            Text(loadError?.title ?? "No claims matched this filter.")
                .font(.raBody)
                .foregroundStyle(Color.raTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowBackground(Color.clear)
    }

    /// The game half is the tap target; the byline sits outside it.
    ///
    /// A username inside a row-sized Button cannot be tapped — the outer
    /// button swallows it — so the developer's name lives on its own line
    /// below, indented to the title, where it is a link in its own right.
    private func row(_ claim: SetClaim) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                selectedGameID.wrappedValue = GameSheetItem(id: claim.gameID)
            } label: {
                HStack(spacing: 12) {
                    KFImage(RAImageURL.gameIcon(claim.gameIcon))
                        .resizable()
                        .placeholder {
                            RoundedRectangle(cornerRadius: 8).fill(Color.raSurfaceSunken)
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(claim.gameTitle)
                            .font(.raBody.weight(.semibold))
                            .foregroundStyle(Color.raTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(claim.consoleName)
                            .font(.raCaption)
                            .foregroundStyle(Color.raTextSecondary)
                    }

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Text(claim.kind.label)
                    .font(.raStatSmall)
                    .foregroundStyle(claim.isRevision ? Color.raTextSecondary : Color.raAccent)
                separator
                RAUsernameLink(claim.user, font: .raStatSmall)
                if let relative = claim.relativeNewsDate {
                    separator
                    Text(relative)
                        .font(.raStatSmall)
                        .foregroundStyle(Color.raTextTertiary)
                }
                Spacer(minLength: 0)
            }
            // Aligned with the title above: icon width plus the stack spacing.
            .padding(.leading, 56)
        }
        .padding(.vertical, 2)
    }

    private var separator: some View {
        Text("·")
            .font(.raStatSmall)
            .foregroundStyle(Color.raTextTertiary)
    }

    private func load(force: Bool) async {
        // Claims change by the day, not by the minute; a tab switch reuses
        // what is already loaded and pull-to-refresh asks again.
        if !force && network.setClaimsLoaded {
            isLoading = false
            return
        }
        isLoading = !network.setClaimsLoaded
        loadError = await network.getSetClaims()
        isLoading = false
    }
}
