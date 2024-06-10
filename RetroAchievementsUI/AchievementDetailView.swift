//
//  AchievementDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct AchievementDetailView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var achievement: Achievement
    
    
    var body: some View {
        HStack{
            AsyncImage(url: URL(string: "https://retroachievements.org/Badge/" + (achievement.badgeName) + ".png"))
            { phase in
                switch phase {
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                case .success(let image):
                    image
                default:
                    ProgressView()
                }
            }
            .clipShape(.rect(cornerRadius: 10))
            
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
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
            
        }
        
    }
        
}

#Preview {
    Text("Hello World!")
//    GameSummaryView()
//        .environmentObject(Network())
}
