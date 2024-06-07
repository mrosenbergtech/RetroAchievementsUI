//
//  GameSummaryView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct GameSummaryView: View {
    @EnvironmentObject var network: Network
    
    var body: some View {
        VStack {
            Text(network.gameSummaries.first?.title ?? "Game Title")
            AsyncImage(url: URL(string: "https://retroachievements.org/" + (network.gameSummaries.first?.imageIcon ?? "UserPic/mrosen97")))
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
            
            ProgressView(value: (Float(network.gameSummaries.first?.userCompletion.dropLast(1) ?? "0.0") ?? 0.0) / 100)
                .padding()
        }
    }
}

#Preview {
    GameSummaryView()
        .environmentObject(Network())
}
