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
            KFImage(URL(string: "https://retroachievements.org/Badge/" + (achievement.badgeName) + ".png"))
                .frame(width: 64, height: 64)
            
            VStack(alignment: .center) {
                // Achievement Title
                ScrollingText(text: achievement.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                
                HStack{
                    // Achievement Points
                    HStack{
                        Image(systemName: "trophy.circle")
                        Text(String(achievement.points))
                    }
                    
                    // Unlock Status
                    HStack{
                        if (achievement.dateEarned != nil){
                            Image(systemName: "lock.open.fill")
                            Text("Unlocked")
                        } else {
                            Image(systemName: "lock.fill")
                            Text("Locked")
                        }
                    }
                }
                
                ScrollingText(text: achievement.description, font: .preferredFont(forTextStyle: .caption1), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                    .padding(.horizontal)
            }
            
        }
        .frame(maxWidth: .infinity)
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
        
    }
        
}

#Preview {
    @State var hardcoreMode: Bool = true
    let previewAchievement = Achievement(id: 48643, numAwarded: 2709, numAwardedHardcore: 2180, title: "Full Power", description: "Grab 120 Power Stars.", points: 25, trueRatio: 0, author: "SamuraiGoroh", dateModified: "06 Dec, 2021 23:01", dateCreated: "25 May, 2017 17:37", badgeName: "84225", displayOrder: 1, memAddr: "N/A", type: "N/A", dateEarnedHardcore: "27 Jan, 2024, 19:45", dateEarned: "27 Jan, 2024, 19:45")
    return AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: previewAchievement).padding()
}
