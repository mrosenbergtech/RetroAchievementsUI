//
//  AchievementDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct AchievementDetailView: View {
    @Binding var hardcoreMode: Bool
    var achievement: Achievement
    
    var body: some View {
        HStack{
            KFImage(URL(string: "https://retroachievements.org/Badge/" + (achievement.badgeName) + (hardcoreMode ? ((achievement.dateEarnedHardcore != nil) ? "" : "_lock") : ((achievement.dateEarned != nil) ? "" : "_lock"))  + ".png"))
                .frame(width: 64, height: 64)
            
            VStack(alignment: .center) {
                // Achievement Title
                ScrollingText(text: achievement.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                
                HStack{
                    // Achievement Points
                    Image(systemName: "command.circle.fill")
                    Text(String(achievement.points))
                        .scaledToFit()
                    
                    // Achievement Type
                    if achievement.type == "missable"{
                        HStack{
                            Image(systemName: "questionmark.circle.dashed")
                            Text("Missable")
                                .scaledToFit()
                        }.minimumScaleFactor(0.01)
                    } else if achievement.type == "progression" {
                        HStack{
                            Image(systemName: "checkmark.circle")
                            Text("Progression")
                                .scaledToFit()
                        }.minimumScaleFactor(0.01)
                    } else if achievement.type == "win_condition" {
                        HStack{
                            Image(systemName: "checkmark.circle.fill")
                            Text("Win Condition")
                                .scaledToFit()
                        }.minimumScaleFactor(0.01)
                    }
                    
                    // Achievement Unlock Status
                    HStack{
                        if (achievement.dateEarned != nil){
                            Image(systemName: "lock.open.fill")
                            Text("Unlocked")
                                .scaledToFit()
                        } else {
                            Image(systemName: "lock.fill")
                            Text("Locked")
                                .scaledToFit()
                        }
                    }
                }
                
                // Achievement Description
                ScrollingText(text: achievement.description, font: .preferredFont(forTextStyle: .caption1), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
        
    }
        
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let previewAchievement = Achievement(id: 48643, numAwarded: 2709, numAwardedHardcore: 2180, title: "Full Power", description: "Grab 120 Power Stars.", points: 25, trueRatio: 0, author: "SamuraiGoroh", dateModified: "06 Dec, 2021 23:01", dateCreated: "25 May, 2017 17:37", badgeName: "84225", displayOrder: 1, memAddr: "N/A", type: "progression", dateEarnedHardcore: "27 Jan, 2024, 19:45", dateEarned: "27 Jan, 2024, 19:45")
    return AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: previewAchievement).padding()
}
