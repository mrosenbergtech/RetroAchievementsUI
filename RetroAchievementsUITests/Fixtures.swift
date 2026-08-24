//
//  Fixtures.swift
//  RetroAchievementsUITests
//
//  Sample API payloads, written inline rather than as bundled resources so the
//  test target needs no resource build phase and each fixture sits next to the
//  shape it documents.
//
//  Field names and value shapes mirror real RetroAchievements responses,
//  including the awkward parts: PascalCase keys, `AwardData` being null for
//  site awards, and GetGameInfoAndUserProgress returning achievements as a
//  dictionary keyed by stringified ID.
//

import Foundation

enum Fixtures {

    static func data(_ json: String) -> Data {
        Data(json.utf8)
    }

    // MARK: - GetUserAwards

    /// Two game awards (one mastery, one beaten) plus one site award.
    static let userAwards = data("""
    {
      "TotalAwardsCount": 3,
      "HiddenAwardsCount": 0,
      "MasteryAwardsCount": 1,
      "CompletionAwardsCount": 0,
      "BeatenHardcoreAwardsCount": 1,
      "BeatenSoftcoreAwardsCount": 0,
      "EventAwardsCount": 0,
      "SiteAwardsCount": 1,
      "VisibleUserAwards": [
        {
          "AwardedAt": "2023-05-21T13:16:27+00:00",
          "AwardType": "Mastery/Completion",
          "AwardData": 11278,
          "AwardDataExtra": 1,
          "DisplayOrder": 0,
          "Title": "Super Mario 64",
          "ConsoleID": 2,
          "ConsoleName": "Nintendo 64",
          "Flags": null,
          "ImageIcon": "/Images/047942.png"
        },
        {
          "AwardedAt": "2024-01-02T08:00:00+00:00",
          "AwardType": "Game Beaten",
          "AwardData": 3210,
          "AwardDataExtra": 1,
          "DisplayOrder": 0,
          "Title": "Mario Party",
          "ConsoleID": 2,
          "ConsoleName": "Nintendo 64",
          "Flags": null,
          "ImageIcon": "/Images/099887.png"
        },
        {
          "AwardedAt": "2022-11-11T00:00:00+00:00",
          "AwardType": "Achievement Unlocks Yield 1000 Points",
          "AwardData": null,
          "AwardDataExtra": 0,
          "DisplayOrder": 0,
          "Title": null,
          "ConsoleID": null,
          "ConsoleName": null,
          "Flags": null,
          "ImageIcon": null
        }
      ]
    }
    """)

    /// The same game holding BOTH a mastery and a beaten award — what
    /// filterHighestAwardType exists to collapse.
    static let userAwardsDuplicateGame = data("""
    {
      "TotalAwardsCount": 2,
      "HiddenAwardsCount": 0,
      "MasteryAwardsCount": 1,
      "CompletionAwardsCount": 0,
      "BeatenHardcoreAwardsCount": 1,
      "BeatenSoftcoreAwardsCount": 0,
      "EventAwardsCount": 0,
      "SiteAwardsCount": 0,
      "VisibleUserAwards": [
        {
          "AwardedAt": "2023-01-01T00:00:00+00:00",
          "AwardType": "Game Beaten",
          "AwardData": 11278,
          "AwardDataExtra": 1,
          "DisplayOrder": 0,
          "Title": "Super Mario 64",
          "ConsoleID": 2,
          "ConsoleName": "Nintendo 64",
          "Flags": null,
          "ImageIcon": "/Images/047942.png"
        },
        {
          "AwardedAt": "2023-05-21T13:16:27+00:00",
          "AwardType": "Mastery/Completion",
          "AwardData": 11278,
          "AwardDataExtra": 1,
          "DisplayOrder": 0,
          "Title": "Super Mario 64",
          "ConsoleID": 2,
          "ConsoleName": "Nintendo 64",
          "Flags": null,
          "ImageIcon": "/Images/047942.png"
        }
      ]
    }
    """)

    /// Several site awards — all with `AwardData: null`.
    static let userAwardsSiteOnly = data("""
    {
      "TotalAwardsCount": 3,
      "HiddenAwardsCount": 0,
      "MasteryAwardsCount": 0,
      "CompletionAwardsCount": 0,
      "BeatenHardcoreAwardsCount": 0,
      "BeatenSoftcoreAwardsCount": 0,
      "EventAwardsCount": 0,
      "SiteAwardsCount": 3,
      "VisibleUserAwards": [
        { "AwardedAt": "2022-01-01T00:00:00+00:00", "AwardType": "Site Award A",
          "AwardData": null, "AwardDataExtra": 0, "DisplayOrder": 0,
          "Title": null, "ConsoleID": null, "ConsoleName": null,
          "Flags": null, "ImageIcon": null },
        { "AwardedAt": "2022-02-01T00:00:00+00:00", "AwardType": "Site Award B",
          "AwardData": null, "AwardDataExtra": 0, "DisplayOrder": 0,
          "Title": null, "ConsoleID": null, "ConsoleName": null,
          "Flags": null, "ImageIcon": null },
        { "AwardedAt": "2022-03-01T00:00:00+00:00", "AwardType": "Site Award C",
          "AwardData": null, "AwardDataExtra": 0, "DisplayOrder": 0,
          "Title": null, "ConsoleID": null, "ConsoleName": null,
          "Flags": null, "ImageIcon": null }
      ]
    }
    """)

    /// One hardcore and one softcore award, for the Hardcore Mode filter.
    static let userAwardsMixedHardcore = data("""
    {
      "TotalAwardsCount": 2,
      "HiddenAwardsCount": 0,
      "MasteryAwardsCount": 1,
      "CompletionAwardsCount": 1,
      "BeatenHardcoreAwardsCount": 0,
      "BeatenSoftcoreAwardsCount": 0,
      "EventAwardsCount": 0,
      "SiteAwardsCount": 0,
      "VisibleUserAwards": [
        {
          "AwardedAt": "2023-05-21T13:16:27+00:00",
          "AwardType": "Mastery/Completion",
          "AwardData": 11278,
          "AwardDataExtra": 1,
          "DisplayOrder": 0, "Title": "Hardcore Game",
          "ConsoleID": 2, "ConsoleName": "Nintendo 64",
          "Flags": null, "ImageIcon": "/Images/047942.png"
        },
        {
          "AwardedAt": "2023-06-21T13:16:27+00:00",
          "AwardType": "Mastery/Completion",
          "AwardData": 555,
          "AwardDataExtra": 0,
          "DisplayOrder": 0, "Title": "Softcore Game",
          "ConsoleID": 2, "ConsoleName": "Nintendo 64",
          "Flags": null, "ImageIcon": "/Images/000555.png"
        }
      ]
    }
    """)

    /// Enough game awards to make an N+1 fetch obvious.
    static func userAwardsMany(count: Int) -> Data {
        let entries = (0..<count).map { index in
            """
            {
              "AwardedAt": "2023-05-21T13:16:27+00:00",
              "AwardType": "Mastery/Completion",
              "AwardData": \(1000 + index),
              "AwardDataExtra": 1,
              "DisplayOrder": 0,
              "Title": "Game \(index)",
              "ConsoleID": 2,
              "ConsoleName": "Nintendo 64",
              "Flags": null,
              "ImageIcon": "/Images/0000\(index).png"
            }
            """
        }.joined(separator: ",")

        return data("""
        {
          "TotalAwardsCount": \(count),
          "HiddenAwardsCount": 0,
          "MasteryAwardsCount": \(count),
          "CompletionAwardsCount": 0,
          "BeatenHardcoreAwardsCount": 0,
          "BeatenSoftcoreAwardsCount": 0,
          "EventAwardsCount": 0,
          "SiteAwardsCount": 0,
          "VisibleUserAwards": [\(entries)]
        }
        """)
    }

    // MARK: - GetUserProfile

    static let userProfile = data("""
    {
      "User": "mrosen97",
      "UserPic": "/UserPic/mrosen97.png",
      "MemberSince": "2020-04-01 12:00:00",
      "RichPresenceMsg": "Playing Super Mario 64",
      "LastGameID": 11278,
      "ContribCount": 0,
      "ContribYield": 0,
      "TotalPoints": 2247,
      "TotalSoftcorePoints": 130,
      "TotalTruePoints": 5012,
      "Permissions": 1,
      "Untracked": 0,
      "ID": 12345,
      "UserWallActive": 1,
      "Motto": "For the love of the grind"
    }
    """)

    // MARK: - GetUserCompletionProgress

    static let completionProgress = data("""
    {
      "Count": 2,
      "Total": 2,
      "Results": [
        {
          "GameID": 11278,
          "Title": "Super Mario 64",
          "ImageIcon": "/Images/047942.png",
          "ConsoleID": 2,
          "ConsoleName": "Nintendo 64",
          "MaxPossible": 114,
          "NumAwarded": 114,
          "NumAwardedHardcore": 114,
          "MostRecentAwardedDate": "2023-05-21T13:16:27+00:00",
          "HighestAwardKind": "mastered",
          "HighestAwardDate": "2023-05-21T13:16:27+00:00"
        },
        {
          "GameID": 3210,
          "Title": "Mario Party",
          "ImageIcon": "/Images/099887.png",
          "ConsoleID": 2,
          "ConsoleName": "Nintendo 64",
          "MaxPossible": 56,
          "NumAwarded": 44,
          "NumAwardedHardcore": 44,
          "MostRecentAwardedDate": "2024-01-02T08:00:00+00:00",
          "HighestAwardKind": "beaten-hardcore",
          "HighestAwardDate": "2024-01-02T08:00:00+00:00"
        }
      ]
    }
    """)

    /// HighestAwardKind and HighestAwardDate are null for in-progress games.
    static let completionProgressNullAward = data("""
    {
      "Count": 1,
      "Total": 1,
      "Results": [
        {
          "GameID": 999,
          "Title": "In Progress",
          "ImageIcon": "/Images/000999.png",
          "ConsoleID": 2,
          "ConsoleName": "Nintendo 64",
          "MaxPossible": 50,
          "NumAwarded": 3,
          "NumAwardedHardcore": 1,
          "MostRecentAwardedDate": "2024-01-02T08:00:00+00:00",
          "HighestAwardKind": null,
          "HighestAwardDate": null
        }
      ]
    }
    """)

    // MARK: - GetGameInfoAndUserProgress

    static let gameInfoAndUserProgress = data("""
    {
      "ID": 11278,
      "Title": "Super Mario 64",
      "ConsoleID": 2,
      "ForumTopicID": 100,
      "Flags": null,
      "ImageIcon": "/Images/047942.png",
      "ImageTitle": "/Images/047943.png",
      "ImageIngame": "/Images/047944.png",
      "ImageBoxArt": "/Images/047945.png",
      "Publisher": "Nintendo",
      "Developer": "Nintendo EAD",
      "Genre": "Platformer",
      "Released": "1996-06-23",
      "IsFinal": false,
      "RichPresencePatch": "abc",
      "players_total": 1000,
      "achievements_published": 114,
      "points_total": 900,
      "GuideURL": null,
      "ConsoleName": "Nintendo 64",
      "ParentGameID": null,
      "NumDistinctPlayers": 1000,
      "NumAchievements": 114,
      "Achievements": {
        "12345": {
          "ID": 12345,
          "NumAwarded": 900,
          "NumAwardedHardcore": 700,
          "Title": "Bob-omb Battlefield",
          "Description": "Collect the first star",
          "Points": 5,
          "TrueRatio": 6,
          "Author": "someone",
          "DateModified": "2020-01-01 00:00:00",
          "DateCreated": "2019-01-01 00:00:00",
          "BadgeName": "54321",
          "DisplayOrder": 1,
          "MemAddr": "deadbeef",
          "Type": "progression",
          "DateEarned": "2023-05-01 10:00:00",
          "DateEarnedHardcore": "2023-05-01 10:00:00"
        }
      },
      "NumAwardedToUser": 114,
      "NumAwardedToUserHardcore": 114,
      "NumDistinctPlayersCasual": 900,
      "NumDistinctPlayersHardcore": 700,
      "UserCompletion": "100.00%",
      "UserCompletionHardcore": "100.00%",
      "HighestAwardKind": "mastered",
      "HighestAwardDate": "2023-05-21T13:16:27+00:00"
    }
    """)

    // MARK: - Other endpoints

    static let consoleIDs = data("""
    [
      { "ID": 2, "Name": "Nintendo 64", "IconURL": "https://example.com/n64.png",
        "Active": true, "IsGameSystem": true },
      { "ID": 1, "Name": "Mega Drive", "IconURL": "https://example.com/md.png",
        "Active": true, "IsGameSystem": true },
      { "ID": 14, "Name": "Neo Geo CD", "IconURL": "https://example.com/ngcd.png",
        "Active": true, "IsGameSystem": true }
    ]
    """)

    static let gameList = data("""
    [
      { "Title": "Super Mario 64", "ID": 11278, "ConsoleID": 2,
        "ConsoleName": "Nintendo 64", "ImageIcon": "/Images/047942.png",
        "NumAchievements": 114, "NumLeaderboards": 10, "Points": 900,
        "DateModified": "2024-01-01 00:00:00", "ForumTopicID": 100 }
    ]
    """)

    static let recentlyPlayed = data("""
    [
      {
        "GameID": 11278, "ConsoleID": 2, "ConsoleName": "Nintendo 64",
        "Title": "Super Mario 64", "ImageIcon": "/Images/047942.png",
        "ImageTitle": "/Images/047943.png", "ImageIngame": "/Images/047944.png",
        "ImageBoxArt": "/Images/047945.png",
        "LastPlayed": "2024-01-02 08:00:00",
        "AchievementsTotal": 114, "NumPossibleAchievements": 114,
        "PossibleScore": 900, "NumAchieved": 114, "ScoreAchieved": 900,
        "NumAchievedHardcore": 114, "ScoreAchievedHardcore": 900
      }
    ]
    """)

    static let recentAchievements = data("""
    [
      {
        "Date": "2024-01-02 08:00:00", "HardcoreMode": 1, "AchievementID": 12345,
        "Title": "Bob-omb Battlefield", "Description": "Collect the first star",
        "BadgeName": "54321", "Points": 5, "TrueRatio": 6, "Type": "progression",
        "Author": "someone", "GameID": 11278, "GameTitle": "Super Mario 64",
        "GameIcon": "/Images/047942.png", "ConsoleName": "Nintendo 64",
        "BadgeURL": "/Badge/54321.png", "GameURL": "/game/11278"
      }
    ]
    """)

    /// Captured from API_GetComments.php (t=2). Includes the automated
    /// "Server" changelog entries the real feed is full of, and two comments
    /// from the same user to prove ULID is not a per-comment identity.
    static let achievementComments = data("""
    {
      "Count": 4,
      "Total": 31,
      "Results": [
        { "User": "Server", "ULID": "019Z8BMP7E37YNRVDSP8SV266G",
          "Submitted": "2019-02-15T21:02:16.000000Z",
          "CommentText": "SporyTike edited this achievement." },
        { "User": "junyor789", "ULID": "01ABCDEFGHIJKLMNOPQRSTUVWX",
          "Submitted": "2021-07-04T10:11:12.000000Z",
          "CommentText": "Took me ages to get this one." },
        { "User": "junyor789", "ULID": "01ABCDEFGHIJKLMNOPQRSTUVWX",
          "Submitted": "2021-07-05T09:00:00.000000Z",
          "CommentText": "Actually the trick is to wait." },
        { "User": "Server", "ULID": "019Z8BMP7E37YNRVDSP8SV266G",
          "Submitted": "2022-01-01T00:00:00.000000Z",
          "CommentText": "someone edited this achievement." }
      ]
    }
    """)

    /// `perGame` recent achievements for each of `games`, to prove the rarity
    /// prefetch keys on distinct games rather than on achievements.
    static func recentAchievementsAcrossGames(games: [Int], perGame: Int) -> Data {
        var entries: [String] = []
        var id = 1
        for game in games {
            for _ in 0..<perGame {
                entries.append("""
                { "Date": "2024-01-02 08:00:00", "HardcoreMode": 1,
                  "AchievementID": \(id), "Title": "A\(id)", "Description": "",
                  "BadgeName": "b", "Points": 5, "TrueRatio": 5, "Type": null,
                  "Author": "a", "GameID": \(game), "GameTitle": "Game \(game)",
                  "GameIcon": "/i.png", "ConsoleName": "N64",
                  "BadgeURL": "/Badge/b.png", "GameURL": "/game/\(game)" }
                """)
                id += 1
            }
        }
        return data("[\(entries.joined(separator: ","))]")
    }

    /// An event game, as RetroAchievements really returns them: no release
    /// date, developer, genre or parent game. "Achievement of the Week" and
    /// friends turn up in recent achievements constantly, and a non-optional
    /// `released` used to fail the whole decode on these.
    static let gameInfoEventGame = data("""
    {
      "ID": 33480, "Title": "Achievement of the Week 2018 - Evergreen",
      "ConsoleID": 101, "ForumTopicID": null, "Flags": null,
      "ImageIcon": "/Images/000001.png", "ImageTitle": "/Images/000002.png",
      "ImageIngame": "/Images/000003.png", "ImageBoxArt": "/Images/000004.png",
      "Publisher": null, "Developer": null, "Genre": null,
      "Released": null, "ReleasedAtGranularity": null,
      "IsFinal": false, "RichPresencePatch": "", "players_total": 500,
      "achievements_published": 1, "points_total": 10, "GuideURL": null,
      "ConsoleName": "Events", "ParentGameID": null,
      "NumDistinctPlayers": 500, "NumAchievements": 1,
      "Achievements": {
        "77": { "ID": 77, "NumAwarded": 50, "NumAwardedHardcore": 40,
          "Title": "Weekly", "Description": "", "Points": 10, "TrueRatio": 10,
          "Author": "a", "DateModified": null, "DateCreated": "2018-01-01 00:00:00",
          "BadgeName": "b", "DisplayOrder": 1, "MemAddr": "", "Type": null }
      },
      "NumAwardedToUser": 1, "NumAwardedToUserHardcore": 1,
      "NumDistinctPlayersCasual": 500, "NumDistinctPlayersHardcore": 400,
      "UserCompletion": "100%", "UserCompletionHardcore": "100%",
      "HighestAwardKind": null, "HighestAwardDate": null
    }
    """)

    /// A game with no recorded players — the divide-by-zero guard.
    static let gameInfoZeroPlayers = data("""
    {
      "ID": 11278, "Title": "Unplayed", "ConsoleID": 2, "ForumTopicID": null,
      "Flags": null, "ImageIcon": "/i.png", "ImageTitle": "/t.png",
      "ImageIngame": "/g.png", "ImageBoxArt": "/b.png",
      "Publisher": null, "Developer": null, "Genre": null, "Released": "",
      "IsFinal": false, "RichPresencePatch": "", "players_total": 0,
      "achievements_published": 1, "points_total": 5, "GuideURL": null,
      "ConsoleName": "Nintendo 64", "ParentGameID": null,
      "NumDistinctPlayers": 0, "NumAchievements": 1,
      "Achievements": {
        "12345": { "ID": 12345, "NumAwarded": 0, "NumAwardedHardcore": 0,
          "Title": "T", "Description": "", "Points": 5, "TrueRatio": 5,
          "Author": "a", "DateModified": null, "DateCreated": "",
          "BadgeName": "b", "DisplayOrder": 1, "MemAddr": "", "Type": null }
      },
      "NumAwardedToUser": 0, "NumAwardedToUserHardcore": 0,
      "NumDistinctPlayersCasual": 0, "NumDistinctPlayersHardcore": 0,
      "UserCompletion": "0%", "UserCompletionHardcore": "0%",
      "HighestAwardKind": null, "HighestAwardDate": null
    }
    """)

    static let malformed = data("{ this is not valid json ")
    static let emptyArray = data("[]")
}
