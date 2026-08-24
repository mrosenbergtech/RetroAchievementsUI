//
//  RATheme.swift
//  RetroAchievementsUI
//
//  Semantic color tokens.
//
//  Two distinct palettes live here:
//
//  • App chrome (raSurface, raTextPrimary, …) adapts to light/dark.
//  • Card stock and rarity materials are FIXED dark regardless of appearance.
//    A trading card is a physical object; its ink and foil do not invert when
//    the room lights change, and metallic gradients read as muddy grey when
//    lightened for a light-mode background.
//

import SwiftUI
import UIKit

// MARK: - Dynamic color helper

extension Color {
    /// Builds an appearance-adaptive color from two hex values.
    static func raDynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static func raFixed(_ hex: UInt32) -> Color {
        Color(UIColor(hex: hex))
    }
}

extension UIColor {
    /// 0xRRGGBB
    convenience init(hex: UInt32) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue:  CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - App chrome

extension Color {
    /// Page background.
    static let raSurface = Color.raDynamic(light: 0xF4F5F7, dark: 0x0E0F12)
    /// Cards, rows, grouped-list cells.
    static let raSurfaceRaised = Color.raDynamic(light: 0xFFFFFF, dark: 0x191B20)
    /// Chips, wells, inset controls.
    static let raSurfaceSunken = Color.raDynamic(light: 0xE9EBEF, dark: 0x232630)
    static let raSeparator = Color.raDynamic(light: 0xD8DBE0, dark: 0x2C3038)

    static let raTextPrimary = Color.raDynamic(light: 0x14161A, dark: 0xF2F4F7)
    static let raTextSecondary = Color.raDynamic(light: 0x5A616B, dark: 0x9AA2AE)
    static let raTextTertiary = Color.raDynamic(light: 0x8A919B, dark: 0x6B7280)

    /// RetroAchievements' own brand gold — used sparingly, for accent only.
    static let raAccent = Color.raDynamic(light: 0xB8860B, dark: 0xE3B341)
}

// MARK: - Rarity materials

/// The visual treatment for one award tier.
///
/// A "material" is the frame metal plus the stock it is printed on. Grouping
/// them here keeps `RACardFaceView` free of per-tier switches.
struct RarityMaterial {
    /// Multi-stop metallic sweep used for the card frame.
    let metal: [Color]
    /// Bright edge catching the light — a 1px inner bevel, not a glow.
    let bevelHighlight: Color
    /// Card stock the art and nameplate sit on.
    let stock: [Color]
    /// Ink for the tier label in the stat block.
    let ink: Color
    /// Whether this tier gets a foil sheen sweep.
    let isFoil: Bool
    /// Peak opacity of that sheen. Only meaningful when `isFoil`.
    var foilIntensity: Double = 0.18

    // MARK: - Non-award materials
    //
    // Games and achievements use the same card face, so they need materials
    // too. The game material sits deliberately below the award ladder: an
    // unbeaten game must never out-shine a mastery.

    /// A game the user has started but not yet beaten.
    static let unbeaten = RarityMaterial(
        metal: [.raFixed(0x3A3F47), .raFixed(0x555C66), .raFixed(0x3A3F47)],
        bevelHighlight: .raFixed(0x6C737D),
        stock: [.raFixed(0x14161A), .raFixed(0x0C0E11)],
        ink: .raFixed(0x7E8691),
        isFoil: false
    )

    /// An unlocked achievement whose rarity cannot be computed — the profile's
    /// Recent Achievements deck, which has no award counts to work from. Warm
    /// and neutral: it reads as earned without claiming a tier.
    static let achievementUnranked = RarityMaterial(
        metal: [.raFixed(0x6E4E12), .raFixed(0xC9A44A), .raFixed(0x8A6212), .raFixed(0x6E4E12)],
        bevelHighlight: .raFixed(0xEBD08A),
        stock: [.raFixed(0x1B1710), .raFixed(0x100D09)],
        ink: .raFixed(0xE0BC63),
        isFoil: false
    )

    /// Achievement rarity, on a gem palette deliberately distinct from the
    /// award ladder's metals — an Epic achievement must not be mistaken for a
    /// mastery, so no tier here reuses gold, silver, bronze or event violet
    /// outright. Only Legendary is foiled, mirroring how only the top of the
    /// award ladder shines.
    static func of(_ rarity: AchievementRarity) -> RarityMaterial {
        switch rarity {

        case .common:
            return RarityMaterial(
                metal: [.raFixed(0x3D444D), .raFixed(0x5A626D), .raFixed(0x3D444D)],
                bevelHighlight: .raFixed(0x717A85),
                stock: [.raFixed(0x14161A), .raFixed(0x0C0E11)],
                ink: .raFixed(0x8A929D),
                isFoil: false
            )

        case .uncommon:
            return RarityMaterial(
                metal: [.raFixed(0x15503C), .raFixed(0x2E9B6E), .raFixed(0x15503C)],
                bevelHighlight: .raFixed(0x62D3A4),
                stock: [.raFixed(0x0F1815), .raFixed(0x0A0F0D)],
                ink: .raFixed(0x4FC392),
                isFoil: false
            )

        case .rare:
            return RarityMaterial(
                metal: [.raFixed(0x123A6B), .raFixed(0x2E76C9), .raFixed(0x123A6B)],
                bevelHighlight: .raFixed(0x6FB0F0),
                stock: [.raFixed(0x0E141F), .raFixed(0x090D14)],
                ink: .raFixed(0x5AA0E8),
                isFoil: false
            )

        case .epic:
            return RarityMaterial(
                metal: [.raFixed(0x5A1466), .raFixed(0xA83CC0), .raFixed(0xD98BE8),
                        .raFixed(0x8A2AA0), .raFixed(0x5A1466)],
                bevelHighlight: .raFixed(0xE7A9F2),
                stock: [.raFixed(0x18101C), .raFixed(0x0F0A12)],
                ink: .raFixed(0xC77BDA),
                isFoil: false
            )

        case .legendary:
            // The only foiled achievement tier — a genuinely punishing unlock.
            return RarityMaterial(
                metal: [.raFixed(0x7A3A05), .raFixed(0xF0902A), .raFixed(0xFFD08A),
                        .raFixed(0xC96A12), .raFixed(0x7A3A05), .raFixed(0xF5A94E),
                        .raFixed(0x7A3A05)],
                bevelHighlight: .raFixed(0xFFE0B2),
                stock: [.raFixed(0x1C1309), .raFixed(0x110B05)],
                ink: .raFixed(0xF7B25C),
                isFoil: true,
                foilIntensity: 0.26
            )
        }
    }

    static func of(_ tier: AwardTier) -> RarityMaterial {
        switch tier {

        case .mastered:
            // Gold foil — the top of the ladder, the only animated sheen.
            return RarityMaterial(
                metal: [
                    .raFixed(0x6E4E12), .raFixed(0xE8C25A), .raFixed(0xFFF1BC),
                    .raFixed(0xD9A93A), .raFixed(0x7A5714), .raFixed(0xF0CE72),
                    .raFixed(0x6E4E12),
                ],
                bevelHighlight: .raFixed(0xFFF6D6),
                stock: [.raFixed(0x1E1710), .raFixed(0x120E0A)],
                ink: .raFixed(0xF5D479),
                isFoil: true,
                foilIntensity: 0.30
            )

        case .completed:
            // Silver — cooler, still metallic, static sheen only.
            return RarityMaterial(
                metal: [
                    .raFixed(0x5C636D), .raFixed(0xC8CFD8), .raFixed(0xF2F6FA),
                    .raFixed(0xAEB6C0), .raFixed(0x646B75), .raFixed(0xD5DCE4),
                    .raFixed(0x5C636D),
                ],
                bevelHighlight: .raFixed(0xF7FAFD),
                stock: [.raFixed(0x161A20), .raFixed(0x0D1014)],
                ink: .raFixed(0xD7DEE7),
                isFoil: true,
                foilIntensity: 0.18
            )

        case .beatenHardcore:
            // Bronze — warm and matte. No foil; the ladder has to have a floor
            // for the top of it to mean anything.
            return RarityMaterial(
                metal: [
                    .raFixed(0x5A3617), .raFixed(0xA96A3B), .raFixed(0xC98A4B),
                    .raFixed(0x8A5A2E), .raFixed(0x5A3617),
                ],
                bevelHighlight: .raFixed(0xE0AC79),
                stock: [.raFixed(0x191512), .raFixed(0x0F0C0A)],
                ink: .raFixed(0xC98A4B),
                isFoil: false
            )

        case .beatenSoftcore:
            // Plain stock — flat single-tone border, no metal at all.
            return RarityMaterial(
                metal: [.raFixed(0x666D77), .raFixed(0x666D77)],
                bevelHighlight: .raFixed(0x878E98),
                stock: [.raFixed(0x15171B), .raFixed(0x0D0F12)],
                ink: .raFixed(0x9AA2AE),
                isFoil: false
            )

        case .site:
            // Event stock — violet ink, deliberately off the metal ladder so
            // events read as a different category rather than a rarity step.
            return RarityMaterial(
                metal: [
                    .raFixed(0x3F2A80), .raFixed(0x7C5CD6), .raFixed(0xC7B4F5),
                    .raFixed(0x6A4BC4), .raFixed(0x3F2A80),
                ],
                bevelHighlight: .raFixed(0xD9CCFF),
                stock: [.raFixed(0x171425), .raFixed(0x0E0C16)],
                ink: .raFixed(0xB9A5F0),
                isFoil: false
            )
        }
    }
}

// MARK: - Card ink

extension Color {
    /// Text on card stock. Always light — card stock is always dark.
    static let raCardPrimary = Color.raFixed(0xF2F0EA)
    static let raCardSecondary = Color.raFixed(0x9C978C)
    static let raCardRule = Color.white.opacity(0.10)
}
