//
//  AwardsCollectionView.swift
//  RetroAchievementsUI
//
//  Full-screen award collection: a grid of trading cards with rarity filters
//  and sorting.
//

import SwiftUI

struct AwardsCollectionView: View {
    @EnvironmentObject var network: Network
    @Environment(\.selectedGameID) private var selectedGameID: Binding<GameSheetItem?>
    @Binding var hardcoreMode: Bool

    @State private var filter: RarityFilter = .all
    @State private var sort: SortOrder = .rarity
    @State private var selected: AwardCardModel?

    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: - Filtering & sorting

    enum RarityFilter: String, CaseIterable, Identifiable {
        case all, mastered, completed, beaten, events
        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:       return "All"
            case .mastered:  return "Mastered"
            case .completed: return "Completed"
            case .beaten:    return "Beaten"
            case .events:    return "Events"
            }
        }

        var tint: Color {
            switch self {
            case .all:       return .raTextSecondary
            case .mastered:  return .raFixed(0xE8C25A)
            case .completed: return .raFixed(0xC8CFD8)
            case .beaten:    return .raFixed(0xC98A4B)
            case .events:    return .raFixed(0x9C82E8)
            }
        }

        func matches(_ tier: AwardTier) -> Bool {
            switch self {
            case .all:       return true
            case .mastered:  return tier == .mastered
            case .completed: return tier == .completed
            case .beaten:    return tier == .beatenHardcore || tier == .beatenSoftcore
            case .events:    return tier == .site
            }
        }
    }

    enum SortOrder: String, CaseIterable, Identifiable {
        case rarity, recent, title, console
        var id: String { rawValue }

        var label: String {
            switch self {
            case .rarity:  return "Rarity"
            case .recent:  return "Most Recent"
            case .title:   return "Title"
            case .console: return "Console"
            }
        }

        var systemImage: String {
            switch self {
            case .rarity:  return "rosette"
            case .recent:  return "clock"
            case .title:   return "textformat"
            case .console: return "gamecontroller"
            }
        }
    }

    private var allCards: [AwardCardModel] {
        network.awardCards(hardcoreMode: hardcoreMode)
    }

    private var cards: [AwardCardModel] {
        let filtered = allCards.filter { filter.matches($0.tier) }

        switch sort {
        case .recent:
            return filtered.sorted {
                ($0.awardedAt ?? .distantPast) > ($1.awardedAt ?? .distantPast)
            }
        case .rarity:
            // Rarity descending, then most recent within a tier.
            return filtered.sorted {
                $0.tier == $1.tier
                    ? ($0.awardedAt ?? .distantPast) > ($1.awardedAt ?? .distantPast)
                    : $0.tier > $1.tier
            }
        case .title:
            return filtered.sorted { $0.title.lowercased() < $1.title.lowercased() }
        case .console:
            return filtered.sorted {
                let a = $0.consoleName ?? "\u{10FFFF}"   // site awards sort last
                let b = $1.consoleName ?? "\u{10FFFF}"
                return a == b ? $0.title.lowercased() < $1.title.lowercased() : a < b
            }
        }
    }

    private func count(for filter: RarityFilter) -> Int {
        allCards.filter { filter.matches($0.tier) }.count
    }

    // MARK: - Grid rows

    private var columnCount: Int { sizeClass == .regular ? 5 : 3 }

    /// Cards chunked into fixed-width rows.
    ///
    /// A List of grid rows rather than a ScrollView of one huge LazyVGrid: rows
    /// recycle, so a collection of several hundred cards scrolls at the same
    /// cost as a dozen.
    private var rows: [[AwardCardModel]] {
        stride(from: 0, to: cards.count, by: columnCount).map { start in
            Array(cards[start..<min(start + columnCount, cards.count)])
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if cards.isEmpty {
                ContentUnavailableView(
                    "No Awards Here",
                    systemImage: "trophy.slash",
                    description: Text(filter == .all
                        ? "Keep playing to earn mastery and completion awards."
                        : "You have no \(filter.label.lowercased()) awards yet.")
                )
            } else {
                grid
            }
        }
        .background(Color.raSurface)
        .safeAreaInset(edge: .top, spacing: 0) { filterBar }
        .navigationTitle("Awards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(SortOrder.allCases) { order in
                            Label(order.label, systemImage: order.systemImage).tag(order)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
        }
        .sheet(item: $selected) { card in
            AwardCardDetailView(card: card, hardcoreMode: $hardcoreMode)
        }
    }

    /// A game award goes straight to that game; a site award has no game, so it
    /// opens the trading card itself.
    private func open(_ card: AwardCardModel) {
        if let gameID = card.gameID {
            selectedGameID.wrappedValue = GameSheetItem(id: gameID)
        } else {
            selected = card
        }
    }

    private var grid: some View {
        List {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: 12) {
                    ForEach(row) { card in
                        Button {
                            open(card)
                        } label: {
                            AwardCardCell(card: card, hardcoreMode: hardcoreMode)
                        }
                        .buttonStyle(CardPressStyle())
                    }

                    // Keeps a short final row's cards at their normal width
                    // instead of stretching them across the screen.
                    if row.count < columnCount {
                        ForEach(0..<(columnCount - row.count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(RarityFilter.allCases) { option in
                    let isOn = filter == option
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { filter = option }
                    } label: {
                        RAChip(
                            "\(option.label)  \(count(for: option))",
                            tint: option.tint,
                            style: isOn ? .solid : .outline
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(count(for: option) == 0 && option != .all)
                    .opacity(count(for: option) == 0 && option != .all ? 0.35 : 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
        .background(.bar)
    }
}

/// Press feedback for a card: a small scale-down, no tint. Cards are objects,
/// so they should depress rather than highlight.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
