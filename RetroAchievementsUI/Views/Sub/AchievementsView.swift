//
//  AchievementsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct AchievementsView: View {
    @Binding var hardcoreMode: Bool
    @State var selectedAchievementFilter: String = "All"
    var gameSummary: GameSummary
    
    var body: some View {
        Section(header: Text("Achievements")){
            HStack{
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .onTapGesture {
                        selectedAchievementFilter = "All"
                    }
                    .fontWeight((selectedAchievementFilter == "All") ? .bold : .regular)
                    .padding()
                    .background(selectedAchievementFilter == "All" ? .gray : .clear)
                    .clipShape(.rect(cornerRadius: 10))
                
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .onTapGesture {
                        selectedAchievementFilter = "Locked"
                    }
                    .fontWeight((selectedAchievementFilter == "Locked") ? .bold : .regular)
                    .padding()
                    .background(selectedAchievementFilter == "Locked" ? .gray : .clear)
                    .clipShape(.rect(cornerRadius: 10))
                
                Spacer()
                
                Image(systemName: "lock.open.fill")
                    .onTapGesture {
                        selectedAchievementFilter = "Unlocked"
                    }
                    .fontWeight((selectedAchievementFilter == "Unlocked") ? .bold : .regular)
                    .padding()
                    .background(selectedAchievementFilter == "Unlocked" ? .gray : .clear)
                    .clipShape(.rect(cornerRadius: 10))
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .onTapGesture {
                        selectedAchievementFilter = "RequiredToBeat"
                    }
                    .fontWeight((selectedAchievementFilter == "RequiredToBeat") ? .bold : .regular)
                    .padding()
                    .background(selectedAchievementFilter == "RequiredToBeat" ? .gray : .clear)
                    .clipShape(.rect(cornerRadius: 10))
                
                Spacer()
                
                // Only Show Missable Filter If There Are Missable Achievements
                if gameSummary.achievements.keys.filter({ gameSummary.achievements[$0]!.type == "missable" }).count > 0 {
                    Image(systemName: "questionmark.circle.dashed")
                        .onTapGesture {
                            selectedAchievementFilter = "Missable"
                        }
                        .fontWeight((selectedAchievementFilter == "Missable") ? .bold : .regular)
                        .padding()
                        .background(selectedAchievementFilter == "Missable" ? .gray : .clear)
                        .clipShape(.rect(cornerRadius: 10))
                    
                    Spacer()
                }
            }
            
            if selectedAchievementFilter == "All" {
                ForEach(gameSummary.achievements.keys.sorted(), id: \.self) { id in
                    AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: gameSummary.achievements[id]!)
                }
            } else if selectedAchievementFilter == "Locked" {
                ForEach(gameSummary.achievements.keys.filter { gameSummary.achievements[$0]!.dateEarnedHardcore == nil }.sorted(), id: \.self) { id in
                    AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: gameSummary.achievements[id]!)
                }
            } else if selectedAchievementFilter == "Unlocked" {
                ForEach(gameSummary.achievements.keys.filter { gameSummary.achievements[$0]!.dateEarnedHardcore != nil }.sorted(), id: \.self) { id in
                    AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: gameSummary.achievements[id]!)
                }
            } else if selectedAchievementFilter == "Missable" {
                ForEach(gameSummary.achievements.keys.filter { gameSummary.achievements[$0]!.type == "missable" }.sorted(), id: \.self) { id in
                    AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: gameSummary.achievements[id]!)
                }
            } else if selectedAchievementFilter == "RequiredToBeat" {
                if (gameSummary.achievements.keys.filter { gameSummary.achievements[$0]!.type == "win_condition" }.count > 0) {
                    ForEach(gameSummary.achievements.keys.filter { gameSummary.achievements[$0]!.type == "win_condition"
                    }.sorted(), id: \.self) { id in
                        AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: gameSummary.achievements[id]!)
                    }
                }
                
                ForEach(gameSummary.achievements.keys.filter { gameSummary.achievements[$0]!.type == "progression" }.sorted(), id: \.self) { id in
                    AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: gameSummary.achievements[id]!)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let previewAchievementsSetJSONString: String =
"""
{"48638":{"ID":48638,"NumAwarded":26359,"NumAwardedHardcore":14360,"Title":"A New Journey","Description":"Grab your first Power Star.","Points":1,"TrueRatio":1,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:41","DateCreated":"2017-05-25 17:37:31","BadgeName":"84220","DisplayOrder":1,"MemAddr":"96fd0806cdff4b8faa947aacfedcf86c","type":"progression","DateEarnedHardcore":"2023-01-14 21:24:32","DateEarned":"2023-01-14 21:24:32"},"48639":{"ID":48639,"NumAwarded":14002,"NumAwardedHardcore":9093,"Title":"Ready to Fight Bowser","Description":"Grab 8 Power Stars.","Points":3,"TrueRatio":3,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:49","DateCreated":"2017-05-25 17:37:37","BadgeName":"84221","DisplayOrder":2,"MemAddr":"b79fbd24b3ef74ed70e4dc7bf9afecbd","type":"progression","DateEarnedHardcore":"2023-01-14 22:07:45","DateEarned":"2023-01-14 22:07:45"},"48640":{"ID":48640,"NumAwarded":7304,"NumAwardedHardcore":5308,"Title":"Ready to Rematch Bowser","Description":"Grab 30 Power Stars.","Points":5,"TrueRatio":8,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:57","DateCreated":"2017-05-25 17:37:43","BadgeName":"84222","DisplayOrder":3,"MemAddr":"d2cd200a84ff9fb36935d7f3710b081d","type":"progression"}}
"""
    
    let previewAchievementSet: [String : Achievement] = try! JSONDecoder().decode([String : Achievement].self, from: previewAchievementsSetJSONString.data(using: .ascii)!)
    print(previewAchievementSet)
    
    let previewGameSummary: GameSummary = GameSummary(id: 10003, title: "Super Mario 64", consoleID: 1, forumTopicID: 1, flags: nil, imageIcon: "Images/047942", imageTitle: "N/A", imageIngame: "N'A", imageBoxArt: "N/A", publisher: nil, developer: nil, genre: nil, released: "N/A", isFinal: true, richPresencePatch: "N/A", playersTotal: 1, achievementsPublished: 1, pointsTotal: 690, guideURL: nil, consoleName: "Nintendo 64", parentGameID: nil, numDistinctPlayers: 1, numAchievements: 114, achievements: previewAchievementSet, numAwardedToUser: 59, numAwardedToUserHardcore: 59, numDistinctPlayersCasual: 1, numDistinctPlayersHardcore: 1, userCompletion: "N/A", userCompletionHardcore: "N/A", highestAwardKind: "beaten-hardcore", highestAwardDate: nil)

    return AchievementsView(hardcoreMode: $hardcoreMode, gameSummary: previewGameSummary)
}
