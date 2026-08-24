//
//  RAAlphabetIndex.swift
//  RetroAchievementsUI
//
//  The A–Z scrubber that rides the right edge of a long alphabetical list.
//
//  UIKit's `sectionIndexTitles` is not exposed through SwiftUI's List, so this
//  is a hand-rolled overlay driven by a ScrollViewReader. It shows only the
//  letters that actually have entries, so a tap never lands on nothing.
//

import SwiftUI
import UIKit

/// Groups items into alphabetical sections, with a "#" bucket for anything that
/// does not start with a letter.
struct AlphabetSection<Item: Identifiable>: Identifiable {
    let id: String       // the section letter, also the scroll target
    let items: [Item]

    /// Sorts and buckets `items` by the first character of `key`.
    static func build(_ items: [Item], key: (Item) -> String) -> [AlphabetSection<Item>] {
        let grouped = Dictionary(grouping: items) { item -> String in
            // Fold accents so "Pokémon" files under P, and treat digits and
            // symbols as one "#" bucket the way Contacts does.
            let folded = key(item)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            guard let first = folded.first, first.isLetter else { return "#" }
            return String(first).uppercased()
        }

        return grouped
            .map { AlphabetSection(id: $0.key, items: $0.value) }
            // "#" sorts last, matching the system's own index behaviour.
            .sorted { a, b in
                if a.id == "#" { return false }
                if b.id == "#" { return true }
                return a.id < b.id
            }
    }
}

struct RAAlphabetIndex: View {
    let letters: [String]
    let onSelect: (String) -> Void

    @State private var activeLetter: String?
    /// Measured once per layout so the drag can map a y position to a letter.
    @State private var barHeight: CGFloat = 0

    private let rowHeight: CGFloat = 13
    private let haptics = UISelectionFeedbackGenerator()

    var body: some View {
        VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(activeLetter == letter ? Color.raAccent : Color.raTextSecondary)
                    .frame(height: rowHeight)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 18)
        .padding(.vertical, 6)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { barHeight = geo.size.height }
                    .onChange(of: geo.size.height) { _, new in barHeight = new }
            }
        )
        .contentShape(Rectangle())
        .gesture(
            // A single continuous gesture handles both tap and scrub: the drag
            // fires on touch-down with zero minimum distance.
            DragGesture(minimumDistance: 0)
                .onChanged { value in select(at: value.location.y) }
                .onEnded { _ in activeLetter = nil }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Alphabet index")
        .accessibilityHint("Drag to jump to a letter")
        .accessibilityAdjustableAction { direction in
            guard let current = activeLetter ?? letters.first,
                  let index = letters.firstIndex(of: current) else { return }
            let next = direction == .increment ? index + 1 : index - 1
            guard letters.indices.contains(next) else { return }
            activeLetter = letters[next]
            onSelect(letters[next])
        }
    }

    private func select(at y: CGFloat) {
        guard !letters.isEmpty, barHeight > 0 else { return }

        let usable = barHeight - 12          // minus the vertical padding
        let step = usable / CGFloat(letters.count)
        let index = min(letters.count - 1, max(0, Int((y - 6) / step)))
        let letter = letters[index]

        guard letter != activeLetter else { return }
        activeLetter = letter
        haptics.selectionChanged()
        onSelect(letter)
    }
}
