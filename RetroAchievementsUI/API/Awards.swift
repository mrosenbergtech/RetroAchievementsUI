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
}
