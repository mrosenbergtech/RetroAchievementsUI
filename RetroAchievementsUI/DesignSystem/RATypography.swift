//
//  RATypography.swift
//  RetroAchievementsUI
//
//  The app already had consistent type choices — they were just re-typed inline
//  at every call site. Naming them here means a change lands everywhere.
//

import SwiftUI

extension Font {
    /// Usernames, section titles. SF Rounded reads as "game console UI" without
    /// resorting to a novelty pixel face.
    static let raDisplay = Font.system(.title3, design: .rounded).weight(.bold)
    static let raTitle = Font.system(.headline, design: .rounded).weight(.semibold)

    /// Card nameplate. Sized down from .headline so two lines fit the card.
    static let raNameplate = Font.system(size: 14, weight: .bold, design: .rounded)
    static let raNameplateSub = Font.system(size: 10, weight: .medium, design: .rounded)

    /// Numbers that should line up in columns: points, achievement counts.
    static let raStatSmall = Font.system(size: 10, weight: .semibold, design: .monospaced)

    /// The all-caps micro label used by status chips and the card tier badge.
    static let raMicro = Font.system(size: 8, weight: .black)

    static let raBody = Font.system(.subheadline)
    static let raCaption = Font.system(.caption)
}

extension Text {
    /// All-caps micro label with the letter spacing the size needs to stay legible.
    func raMicroLabel() -> some View {
        self.font(.raMicro)
            .tracking(0.6)
            .textCase(.uppercase)
    }
}
