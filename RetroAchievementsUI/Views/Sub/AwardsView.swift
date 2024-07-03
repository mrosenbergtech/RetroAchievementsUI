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
            Section(header: Text("Game Awards")){
                ForEach(network.filterHighestAwardType(awards: network.awards!.visibleUserAwards).filter { $0.consoleID != nil }) { award in
                    if (hardcoreMode && award.awardDataExtra == 1){
                        AwardDetailView(award: award)
                    } else if (!hardcoreMode) {
                        AwardDetailView(award: award)
                    } else {
                        Text(award.awardType)
                    }
                }
            }
            
            if network.awards!.visibleUserAwards.filter({ $0.consoleID == nil }).count > 0 {
                Section(header: Text("Non-Game Awards")) {
                    ForEach(network.awards!.visibleUserAwards.filter { $0.consoleID == nil }) { award in
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
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)

    }
    
    @State var hardcoreMode: Bool = true
    return AwardsView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
