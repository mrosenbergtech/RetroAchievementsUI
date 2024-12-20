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
                ForEach(network.consolesCache?.consolesSortedByKind.sorted {$0.id.lowercased() < $1.id.lowercased()} ?? []) { consoleKind in
                    Section(header: Text(consoleKind.id)){
                        ForEach(consoleKind.consoleIDList, id: \.self) { consoleID in
                            NavigationLink(destination: ConsoleGamesView(hardcoreMode: $hardcoreMode, consoleID: consoleID)) {
                                ConsoleDetailView(console: network.consolesCache?.getConsoleDataByID(consoleID: consoleID) ?? Console(id: -1, name: "Error", iconURL: "Error", active: false, isGameSystem: false), hardcoreMode: $hardcoreMode)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    return ConsolesView(hardcoreMode: $hardcoreMode).environmentObject(network)
}
