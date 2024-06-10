//
//  AchievementsView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    var gameSummary: GameSummary
    
    
    var body: some View {
        Form {
            Section(header: Text("Achievements")){
                ForEach(gameSummary.achievements.keys.sorted(), id: \.self) { id in
                    AchievementDetailView(hardcoreMode: $hardcoreMode, achievement: gameSummary.achievements[id]!)
                }
            }
            
        }
            
    }
        
}

#Preview {
    Text("Hello World!")
//    GameSummaryView()
//        .environmentObject(Network())
}
