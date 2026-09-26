//
//  UserGameCompletionProgress.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import Foundation

struct Awards: Codable {
    let totalAwardsCount: Int
    let hiddenAwardsCount: Int
    let masteryAwardsCount: Int
    let completionAwardsCount: Int
    let beatenHardcoreAwardsCount: Int
    let beatenSoftcoreAwardsCount: Int
    let eventAwardsCount: Int
    let siteAwardsCount: Int
    let visibleUserAwards: [VisibleUserAward]

    enum CodingKeys: String, CodingKey {
        case totalAwardsCount = "TotalAwardsCount"
        case hiddenAwardsCount = "HiddenAwardsCount"
        case masteryAwardsCount = "MasteryAwardsCount"
        case completionAwardsCount = "CompletionAwardsCount"
        case beatenHardcoreAwardsCount = "BeatenHardcoreAwardsCount"
        case beatenSoftcoreAwardsCount = "BeatenSoftcoreAwardsCount"
        case eventAwardsCount = "EventAwardsCount"
        case siteAwardsCount = "SiteAwardsCount"
        case visibleUserAwards = "VisibleUserAwards"
    }
}

struct VisibleUserAward: Codable, Identifiable {
    let awardedAt: String
    let awardType: String
    let id: Int?
    let awardDataExtra: Int
    let displayOrder: Int
    let title: String?
    let consoleID: Int?
    let consoleName: String?
    let flags: Int?
    let imageIcon: String?

    enum CodingKeys: String, CodingKey {
        case awardedAt = "AwardedAt"
        case awardType = "AwardType"
        case id = "AwardData"
        case awardDataExtra = "AwardDataExtra"
        case displayOrder = "DisplayOrder"
        case title = "Title"
        case consoleID = "ConsoleID"
        case consoleName = "ConsoleName"
        case flags = "Flags"
        case imageIcon = "ImageIcon"
    }

    /// Uniquely identifies one award.
    ///
    /// `id` alone cannot: it is `nil` for every site award and repeats across
    /// award types for the same game. Use this wherever an award needs a stable
    /// identity — deduplication, SwiftUI `ForEach`, diffing.
    var awardIdentity: String {
        [id.map(String.init) ?? "site", awardType, String(awardDataExtra), awardedAt]
            .joined(separator: "-")
    }
}

/// What the profile says about a player's finished games, in one line.
///
/// Separate from Awards because it blends two responses: the award counts come
/// from GetUserAwards, the average from GetUserCompletionProgress.
struct CompletionSummary: Equatable {
    let mastered: Int
    let beaten: Int
    /// Mean completion across tracked games, 0–100. Nil when nothing is
    /// tracked yet — an average of no games is not zero.
    let averageCompletion: Double?

    /// "12 mastered · 5 beaten · 45% complete", dropping any part that has
    /// nothing to say.
    var line: String? {
        var parts: [String] = []
        if mastered > 0 { parts.append("\(mastered) mastered") }
        if beaten > 0 { parts.append("\(beaten) beaten") }
        if let averageCompletion {
            parts.append("\(Int(averageCompletion.rounded()))% complete")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
