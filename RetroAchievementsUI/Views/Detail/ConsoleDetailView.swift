//
//  ConsoleDetailView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 6/10/24.
//

import SwiftUI

struct ConsoleDetailView: View {
    var console: Console
    @Binding var hardcoreMode: Bool
    
    var body: some View {
        HStack{
            AsyncImage(url: URL(string: console.iconURL))
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
    let network = Network()
    @State var hardcoreMode: Bool = true
    return ConsoleDetailView(console: network.consolesCache.consoles.first!, hardcoreMode: $hardcoreMode)
}
