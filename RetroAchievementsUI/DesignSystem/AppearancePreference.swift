//
//  AppearancePreference.swift
//  RetroAchievementsUI
//
//  Whether the app follows the phone's light/dark setting or overrides it.
//
//  Asked for in an App Store review of 5.0.1: "a native darkmode toggle, not
//  just one that listens to the mode the whole phone is currently in."
//  Until then the app had no appearance handling at all and simply inherited
//  the system trait.
//
//  This costs almost nothing to honour because every colour in RATheme is
//  built with `UIColor { traits in … }` rather than a fixed value, so flipping
//  the trait at the root repaints the whole palette. Nothing here needs to
//  know about individual colours.
//

import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    /// The default, and what every build before this one did.
    case system
    case light
    case dark

    var id: String { rawValue }

    /// `nil` means "don't override" — SwiftUI then uses the system trait.
    /// This is the whole mechanism: it is handed to `.preferredColorScheme`
    /// once, at the root, and the dynamic colours follow.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    /// The `@AppStorage` key, named once so the App and Settings cannot drift
    /// apart on a typo — the two read the same key rather than passing a
    /// binding down through four views that have no interest in it.
    static let storageKey = "appearance"
}
