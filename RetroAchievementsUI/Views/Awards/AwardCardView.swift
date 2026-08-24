//
//  AwardCardView.swift
//  RetroAchievementsUI
//
//  An award rendered as a trading card.
//
//  The card face itself lives in DesignSystem/RACardFace.swift — games and
//  achievements render through the same one, so a card is a card wherever it
//  appears. This file only maps an award onto that face.
//

import SwiftUI

/// An award card with the one-shot sheen sweep used in carousels and grids.
///
/// The enlarged, motion-tracked presentation is RACardShowcase, which the award
/// and achievement detail screens share.
struct AwardCardCell: View {
    let card: AwardCardModel
    var hardcoreMode: Bool

    var body: some View {
        RACardCell(face: .award(card, hardcoreMode: hardcoreMode))
    }
}
