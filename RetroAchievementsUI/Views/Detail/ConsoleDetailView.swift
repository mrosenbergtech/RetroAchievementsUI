//
//  ConsoleDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI
import Kingfisher

struct ConsoleDetailView: View {
    var console: Console
    @Binding var hardcoreMode: Bool
    
    var body: some View {
        HStack{
            KFImage(URL(string: console.iconURL))
            .clipShape(.rect(cornerRadius: 10))
            .frame(maxHeight: .infinity)
            .scaleEffect(0.75)
                        
            VStack(alignment: .center){
                HStack{
                    VStack{
                        ScrollingText(text: console.name, font: .boldSystemFont(ofSize: 20), leftFade: 15, rightFade: 15, startDelay: 1, alignment: .center)
                            .padding(.horizontal)
                    }
                }

            }
            
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in -20 }
    }
}


#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let network = Network()
    Task {
        await network.authenticateCredentials(webAPIUsername: debugWebAPIUsername, webAPIKey: debugWebAPIKey)
    }
    return ConsoleDetailView(console: network.consolesCache?.consoles.first ?? Console(id: -1, name: "Error", iconURL: "Error", active: false, isGameSystem: false), hardcoreMode: $hardcoreMode)
}
