//
//  AchievementDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI
import Kingfisher

struct AwardDetailView: View {
    @Binding var hardcoreMode: Bool
    var award: VisibleUserAward
    
    var body: some View {
        HStack{
            KFImage(URL(string: "https://retroachievements.org" + (award.imageIcon)))
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(.rect(cornerRadius: 10))
            
            VStack(alignment: .center) {
                // Achievement Title
                ScrollingText(text: award.id, font: .boldSystemFont(ofSize: 15), leftFade: 15, rightFade: 15, startDelay: 3, alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                
                Text(award.awardType)

            }
            
        }
        .frame(maxWidth: .infinity)
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
        
    }
        
}

#Preview {
    @State var hardcoreMode: Bool = true
    let previewAward = VisibleUserAward(awardedAt: "2023-05-21T13:16:27+00:00", awardType: "Game Beaten", awardData: 10003, awardDataExtra: 1, displayOrder: 0, id: "Super Mario 64", consoleID: 2, consoleName: "Nintendo 64", flags: 0, imageIcon: "/Images/047942.png")
    return AwardDetailView(hardcoreMode: $hardcoreMode, award: previewAward).padding()
}
