//
//  ConsolesView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI

struct ConsolesView: View {
    @EnvironmentObject var network: Network
    @Binding var hardcoreMode: Bool
        
    var body: some View {
            NavigationView {
                Form(){
                    ForEach(network.consolesCache.consoles.sorted { $0.name.lowercased() < $1.name.lowercased()}) { console in
                        NavigationLink(destination: ConsoleGamesView(hardcoreMode: $hardcoreMode, consoleID: console.id))
                        {
                            ConsoleDetailView(console: console, hardcoreMode: $hardcoreMode)
                        }
                        
                    }
                        
                }
            }
        }
}

#Preview {
    let network = Network()
    @State var hardcoreMode: Bool = true
    return ConsolesView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
