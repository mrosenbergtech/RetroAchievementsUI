//
//  RAChip.swift
//  RetroAchievementsUI
//
//  The tinted micro-pill used for status badges and filters. Extracted from the
//  ONLINE / HARDCORE badges that were written inline in ProfileHeaderView.
//

import SwiftUI

/// Shared chip geometry, so a row of chips lines up whatever is inside them.
enum RAChipMetrics {
    /// Tall enough for an 8pt label with breathing room; scales with Dynamic
    /// Type through the @ScaledMetric wrappers below.
    static let height: CGFloat = 22
    /// Leading symbols are sized explicitly. Without this they inherit the
    /// body font — 17pt — and a chip with an icon stands visibly taller than
    /// its text-only neighbour, which is what put HARDCORE out of line with
    /// OFFLINE.
    static let symbolSize: CGFloat = 10
}

struct RAChip<Leading: View>: View {
    let text: String
    var tint: Color = .raTextSecondary
    /// Filled chips read as active; outline chips as available-but-off.
    var style: Style = .filled
    @ViewBuilder var leading: Leading

    @ScaledMetric(relativeTo: .caption2) private var height = RAChipMetrics.height

    enum Style {
        case filled
        case outline
        case solid
    }

    var body: some View {
        HStack(spacing: 4) {
            leading
                .font(.system(size: RAChipMetrics.symbolSize, weight: .bold))
            Text(text)
                .raMicroLabel()
                // A chip is a label, not a paragraph: wrapping breaks it
                // mid-word ("AUTHENTICA / TED") the moment the row is tight.
                // It shrinks to fit instead, and only so far before the row
                // has to give it the space.
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
        .foregroundStyle(style == .solid ? Color.white : tint)
        .padding(.horizontal, 7)
        // A fixed height rather than vertical padding: padding makes the chip
        // as tall as its contents, so a dot, a symbol and a bare label each
        // produced a different height in the same row.
        .frame(height: height)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .filled:
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(tint.opacity(0.12))
        case .outline:
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        case .solid:
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(tint)
        }
    }
}

/// A chip with no label, for rows too tight to carry another word.
///
/// Same shape, padding and tint as RAChip so it reads as one of the family;
/// the meaning has to come from the symbol, so use it only where the symbol
/// is unambiguous and the full-text chip exists somewhere else.
struct RAIconChip: View {
    let systemImage: String
    var tint: Color = .raTextSecondary
    var accessibilityLabel: String

    @ScaledMetric(relativeTo: .caption2) private var height = RAChipMetrics.height

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: RAChipMetrics.symbolSize, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            // Same height as its lettered siblings — it sits beside them.
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .accessibilityLabel(accessibilityLabel)
    }
}

extension RAChip where Leading == EmptyView {
    init(_ text: String, tint: Color = .raTextSecondary, style: Style = .filled) {
        self.init(text: text, tint: tint, style: style) { EmptyView() }
    }
}

// MARK: - Convenience constructors

extension RAChip where Leading == Image {
    init(_ text: String, systemImage: String, tint: Color = .raTextSecondary, style: Style = .filled) {
        self.init(text: text, tint: tint, style: style) {
            Image(systemName: systemImage)
        }
    }
}

/// The small status dot used by the ONLINE / OFFLINE chip.
struct RAStatusDot: View {
    var body: some View {
        Circle().frame(width: 5, height: 5)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            RAChip(text: "ONLINE", tint: .green) { RAStatusDot() }
            RAChip("HARDCORE", systemImage: "trophy.circle.fill", tint: .orange)
            RAChip("STANDARD", systemImage: "bolt.circle.fill", tint: .blue)
        }
        HStack {
            RAChip("MASTERED", tint: .raAccent, style: .outline)
            RAChip("ALL", tint: .raAccent, style: .solid)
        }
    }
    .padding()
    .background(Color.raSurface)
}
