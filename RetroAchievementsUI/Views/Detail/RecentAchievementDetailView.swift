//
//  RecentAchievementDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 12/28/24.
//

import SwiftUI
import Kingfisher

struct RecentAchievementDetailView: View {
    @Binding var hardcoreMode: Bool
    var achievement: RecentAchievement
    
    private func formatDateFromString(dateString: String) -> String {
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        
        if let date = inputDateFormatter.date(from: dateString) {
            let outputDateFormatter = DateFormatter()
            outputDateFormatter.dateFormat = "MM/dd/YY"
            return outputDateFormatter.string(from: date)
        }
        
        return "Error"
    }
    
    var body: some View {
        HStack{
            KFImage(URL(string: "https://retroachievements.org/Badge/" + (achievement.badgeName) + ".png"))
                .frame(width: 15, height: 15)
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal)
            
            VStack(alignment: .center) {
                // Achievement Title
                ScrollingText(text: "[" + achievement.gameTitle + "] " + achievement.title, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                
                HStack{
                    // Achievement Points
                    HStack{
                        Image(systemName: "command.circle.fill")
                        Text(String(achievement.points))
                    }
                    
                    // Missable
                    if achievement.type == "missable"{
                        HStack{
                            Image(systemName: "m.circle.fill")
                            Text("Missable")
                        }
                    }
                    
                    // Date Unlocked (Split Text on Space in Timestamp)
                    HStack{
                        Image(systemName: "calendar.circle.fill")
                        Text(formatDateFromString(dateString: achievement.date))
                    }
                }
                .lineLimit(1)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .padding(.horizontal)
            }
            
        }
        .frame(maxWidth: .infinity)
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
        
    }
        
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let previewAchievement = RecentAchievement(id: 60530, date: "2024-12-28 18:55:18", hardcoreMode: 1, title: "Jane, Stop This Crazy Thing!", description: "Win Minecart Mayhem (Fungi Forest or Creepy Castle) without letting go of the Z button (start holding during the explanation).", badgeName: "151782", points: 10, trueRatio: 32, type: "missable", author: "FBernkastelKues", gameTitle: "Donkey Kong 64", gameIcon: "/Images/066626.png", gameID: 10075, consoleName: "Nintendo 64", badgeURL: "/Badge/151763.png", gameURL: "/game/10075")
    return RecentAchievementDetailView(hardcoreMode: $hardcoreMode, achievement: previewAchievement).padding()
}
