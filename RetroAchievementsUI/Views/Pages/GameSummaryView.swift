//
//  GameSummaryView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/7/24.
//

import SwiftUI

struct GameSummaryView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
    @State var gameSummary: GameSummary?
    var gameDetails: GameCompletionProgress
    
    var body: some View {

            VStack {
                
                Text(gameDetails.title)
                    .bold()
                    .scaledToFill()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal)
                
                AsyncImage(url: URL(string: "https://retroachievements.org/" + (gameDetails.imageIcon)))
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
                .padding(.bottom)
                
                Text("Unlocked: " + String(hardcoreMode ? gameDetails.numAwardedHardcore : gameDetails.numAwarded) + " | " + String(gameDetails.maxPossible))
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .bold()
                
                ProgressView(value: Float(hardcoreMode ? gameDetails.numAwardedHardcore : gameDetails.numAwarded) / Float(gameDetails.maxPossible))
                    .padding(.horizontal)
                Spacer()
                    
                if let gameSummary = network.gameSummaries.filter({ $0.id == gameDetails.id}).first {
                    AchievementsView(hardcoreMode: $hardcoreMode, gameSummary: gameSummary)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                network.getRAGameSummary(gameID: gameDetails.id)
            }
        }
        
}

#Preview {
    @State var hardcoreMode: Bool = true
    let network = Network()
    network.authenticateRACredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    
    let previewGameDetailsJSONString: String =
    """
{   "GameID":10003,
    "Title":"Super Mario 64",
    "ImageIcon":"/Images/047942.png",
    "ConsoleID":2,
    "ConsoleName":"Nintendo 64",
    "MaxPossible":114,
    "NumAwarded":59,
    "NumAwardedHardcore":59,
    "MostRecentAwardedDate":"2024-01-28T02:58:59+00:00",
    "HighestAwardKind":"beaten-hardcore",
    "HighestAwardDate":"2023-05-21T13:16:27+00:00"
}
"""
    
    let previewGameSummaryJSONString: String =
"""

{"ID":10003,"Title":"Super Mario 64","ConsoleID":2,"ForumTopicID":4478,"Flags":0,"ImageIcon":"/Images/047942.png","ImageTitle":"/Images/048653.png","ImageIngame":"/Images/048652.png","ImageBoxArt":"/Images/048358.png","Publisher":"Nintendo","Developer":"","Genre":"3D Platforming, Collect-a-thon","Released":"June 23, 1996","IsFinal":0,"RichPresencePatch":"56be6072595d9321361fc2202fc1db09","players_total":27469,"achievements_published":114,"points_total":690,"GuideURL":"","ConsoleName":"Nintendo 64","NumDistinctPlayers":27469,"ParentGameID":null,"NumAchievements":114,"Achievements":{"48638":{"ID":48638,"NumAwarded":26359,"NumAwardedHardcore":14360,"Title":"A New Journey","Description":"Grab your first Power Star.","Points":1,"TrueRatio":1,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:41","DateCreated":"2017-05-25 17:37:31","BadgeName":"84220","DisplayOrder":1,"MemAddr":"96fd0806cdff4b8faa947aacfedcf86c","type":"progression","DateEarnedHardcore":"2023-01-14 21:24:32","DateEarned":"2023-01-14 21:24:32"},"48639":{"ID":48639,"NumAwarded":14002,"NumAwardedHardcore":9093,"Title":"Ready to Fight Bowser","Description":"Grab 8 Power Stars.","Points":3,"TrueRatio":3,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:49","DateCreated":"2017-05-25 17:37:37","BadgeName":"84221","DisplayOrder":2,"MemAddr":"b79fbd24b3ef74ed70e4dc7bf9afecbd","type":"progression","DateEarnedHardcore":"2023-01-14 22:07:45","DateEarned":"2023-01-14 22:07:45"},"48640":{"ID":48640,"NumAwarded":7304,"NumAwardedHardcore":5308,"Title":"Ready to Rematch Bowser","Description":"Grab 30 Power Stars.","Points":5,"TrueRatio":8,"Author":"SamuraiGoroh","DateModified":"2023-06-18 14:47:57","DateCreated":"2017-05-25 17:37:43","BadgeName":"84222","DisplayOrder":3,"MemAddr":"d2cd200a84ff9fb36935d7f3710b081d","type":"progression","DateEarnedHardcore":"2023-01-15 23:58:08","DateEarned":"2023-01-15 23:58:08"}},"NumAwardedToUser":59,"NumAwardedToUserHardcore":59,"NumDistinctPlayersCasual":27469,"NumDistinctPlayersHardcore":27469,"UserCompletion":"51.75%","UserCompletionHardcore":"51.75%"}

"""
    
    do {
        let previewGameDetails: GameCompletionProgress = try JSONDecoder().decode(GameCompletionProgress.self, from: previewGameDetailsJSONString.data(using: .ascii)!)
        let previewGameSummary: GameSummary = try JSONDecoder().decode(GameSummary.self, from: previewGameSummaryJSONString.data(using: .ascii)!)
        network.gameSummaries.append(previewGameSummary)
        return GameSummaryView(hardcoreMode: $hardcoreMode, gameDetails: previewGameDetails).environmentObject(network)
    } catch {
        return Text("Error")
    }
}
