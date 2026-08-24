//
//  RAChip.swift
//  RetroAchievementsUI
//
//  The tinted micro-pill used for status badges and filters. Extracted from the
//  ONLINE / HARDCORE badges that were written inline in ProfileHeaderView.
//

import SwiftUI

struct RAChip<Leading: View>: View {
    let text: String
    var tint: Color = .raTextSecondary
    /// Filled chips read as active; outline chips as available-but-off.
    var style: Style = .filled
    @ViewBuilder var leading: Leading

    enum Style {
        case filled
        case outline
        case solid
    }

    var body: some View {
        HStack(spacing: 4) {
            leading
            Text(text)
                .raMicroLabel()
        }
        .foregroundStyle(style == .solid ? Color.white : tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
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
