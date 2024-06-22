//
//  ConsolesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
        
    var body: some View {
        if ((network.awards?.visibleUserAwards.count ?? 0) > 0){
            VStack{
                ForEach(network.awards!.visibleUserAwards) { award in
                    if (hardcoreMode && award.awardDataExtra == 1){
                        AwardDetailView(hardcoreMode: $hardcoreMode, award: award)
                    } else if (!hardcoreMode) {
                        AwardDetailView(hardcoreMode: $hardcoreMode, award: award)
                    } else {
                        Text(award.awardType)
                    }
                }
            }
        } else {
            Text("No Awards!")
        }
    }
}

#Preview {
    let network = Network()
    network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    @State var hardcoreMode: Bool = true
    return AwardsView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
