//
//  AchievementsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct AchievementsView: View {
    @Binding var hardcoreMode: Bool
    var gameSummary: GameSummary
    /// Owned by GameSummaryView, which presents the detail sheet — a Section
    /// cannot carry its own .sheet reliably.
    @Binding var selectedAchievement: Achievement?

    @State private var filter: Filter = .all
    /// Off by default: a set's own display order is usually its intended
    /// progression, so rarity is an opt-in lens rather than the default.
    @State private var sortByRarity = false

    // MARK: - Filters

    enum Filter: String, CaseIterable, Identifiable {
        case all, unlocked, locked, requiredToBeat, missable
        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:            return "All"
            case .unlocked:       return "Unlocked"
            case .locked:         return "Locked"
            case .requiredToBeat: return "To Beat"
            case .missable:       return "Missable"
            }
        }

        var systemImage: String {
            switch self {
            case .all:            return "trophy.fill"
            case .unlocked:       return "lock.open.fill"
            case .locked:         return "lock.fill"
            case .requiredToBeat: return "flag.checkered"
            case .missable:       return "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .all:            return .raAccent
            case .unlocked:       return .green
            case .locked:         return .raTextSecondary
            case .requiredToBeat: return .blue
            case .missable:       return .orange
            }
        }
    }

    // MARK: - Data

    private var allAchievements: [Achievement] {
        sortByRarity ? gameSummary.achievementsByRarity : gameSummary.orderedAchievements
    }

    private func rarity(_ achievement: Achievement) -> AchievementRarity? {
        achievement.rarity(totalPlayers: gameSummary.numDistinctPlayers)
    }

    private func isUnlocked(_ achievement: Achievement) -> Bool {
        hardcoreMode ? achievement.dateEarnedHardcore != nil
                     : achievement.dateEarned != nil
    }

    private func matches(_ achievement: Achievement, _ filter: Filter) -> Bool {
        switch filter {
        case .all:            return true
        case .unlocked:       return isUnlocked(achievement)
        case .locked:         return !isUnlocked(achievement)
        case .missable:       return achievement.type == "missable"
        case .requiredToBeat: return achievement.type == "progression"
                                  || achievement.type == "win_condition"
        }
    }

    private func count(for filter: Filter) -> Int {
        allAchievements.filter { matches($0, filter) }.count
    }

    private var visible: [Achievement] {
        allAchievements.filter { matches($0, filter) }
    }

    /// Filters with nothing behind them are hidden rather than shown empty —
    /// most sets have no missable achievements at all.
    private var availableFilters: [Filter] {
        Filter.allCases.filter { $0 == .all || count(for: $0) > 0 }
    }

    // MARK: - Body

    /// Emits a List section: the title and filter bar ride along as a sticky
    /// header, so the filters stay reachable while scrolling a long set.
    var body: some View {
        Section {
            if visible.isEmpty {
                RAEmptyRow(icon: "trophy.slash",
                           title: "Nothing Here",
                           message: "No \(filter.label.lowercased()) achievements.")
                    .raListRow()
            } else {
                ForEach(visible) { achievement in
                    Button {
                        selectedAchievement = achievement
                    } label: {
                        AchievementDetailView(hardcoreMode: $hardcoreMode,
                                              achievement: achievement,
                                              rarity: rarity(achievement))
                    }
                    .buttonStyle(.plain)
                    .raListRow()
                }
            }
        } header: {
            VStack(alignment: .leading, spacing: 8) {
                Label("Achievements", systemImage: "trophy")
                    .font(.raTitle)
                    .foregroundStyle(Color.raTextPrimary)
                    .padding(.horizontal, 16)

                filterBar
            }
            .textCase(nil)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets())
            .background(Color.raSurface)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(availableFilters) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { filter = option }
                    } label: {
                        RAChip("\(option.label)  \(count(for: option))",
                               systemImage: option.systemImage,
                               tint: option.tint,
                               style: filter == option ? .solid : .outline)
                    }
                    .buttonStyle(.plain)
                }

                // A sort, not a filter — separated by a rule so it does not
                // read as another way to narrow the list.
                Divider()
                    .frame(height: 18)
                    .overlay(Color.raSeparator)
                    .padding(.horizontal, 2)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { sortByRarity.toggle() }
                } label: {
                    RAChip("Rarest First", systemImage: "sparkles",
                           tint: AchievementRarity.epic.tint,
                           style: sortByRarity ? .solid : .outline)
                }
                .buttonStyle(.plain)
            }
            .scrollTargetLayout()
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }
}

extension Achievement: Identifiable {}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let json = """
    {"48638":{"ID":48638,"NumAwarded":26359,"NumAwardedHardcore":14360,"Title":"A New Journey","Description":"Grab your first Power Star.","Points":1,"TrueRatio":1,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:41","DateCreated":"2017-05-25 17:37:31","BadgeName":"84220","DisplayOrder":1,"MemAddr":"x","Type":"progression","DateEarnedHardcore":"2023-01-14 21:24:32","DateEarned":"2023-01-14 21:24:32"},"48639":{"ID":48639,"NumAwarded":14002,"NumAwardedHardcore":9093,"Title":"Ready to Fight Bowser","Description":"Grab 8 Power Stars.","Points":3,"TrueRatio":3,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:49","DateCreated":"2017-05-25 17:37:37","BadgeName":"84221","DisplayOrder":2,"MemAddr":"y","Type":"missable","DateEarnedHardcore":null,"DateEarned":null},"48640":{"ID":48640,"NumAwarded":7304,"NumAwardedHardcore":5308,"Title":"Ready to Rematch Bowser","Description":"Grab 30 Power Stars.","Points":5,"TrueRatio":8,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:57","DateCreated":"2017-05-25 17:37:43","BadgeName":"84222","DisplayOrder":3,"MemAddr":"z","Type":"win_condition"}}
    """
    let set = try! JSONDecoder().decode([String: Achievement].self, from: Data(json.utf8))
    let summary = GameSummary(
        id: 10003, title: "Super Mario 64", consoleID: 1, forumTopicID: 1, flags: nil,
        imageIcon: "/Images/047942.png", imageTitle: "", imageIngame: "", imageBoxArt: "",
        publisher: nil, developer: nil, genre: nil, released: "1996", isFinal: true,
        richPresencePatch: "", playersTotal: 1, achievementsPublished: 3, pointsTotal: 690,
        guideURL: nil, consoleName: "Nintendo 64", parentGameID: nil, numDistinctPlayers: 1,
        numAchievements: 3, achievements: set, numAwardedToUser: 1,
        numAwardedToUserHardcore: 1, numDistinctPlayersCasual: 1, numDistinctPlayersHardcore: 1,
        userCompletion: "33%", userCompletionHardcore: "33%",
        highestAwardKind: "beaten-hardcore", highestAwardDate: nil)

    return List {
        AchievementsView(hardcoreMode: $hardcoreMode, gameSummary: summary,
                         selectedAchievement: .constant(nil))
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.raSurface)
}
