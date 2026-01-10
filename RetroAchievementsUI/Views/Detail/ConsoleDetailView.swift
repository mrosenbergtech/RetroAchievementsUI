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
        HStack(spacing: 16) {
            // Console Icon
            KFImage(URL(string: console.iconURL))
                .resizable() // Added to ensure frame works correctly
                .placeholder {
                    Color.gray.opacity(0.2)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                }
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                        
            VStack(alignment: .leading, spacing: 4) {
                // Console Name
                // Note: Using ScrollingText as per your original design
                ScrollingText(
                    text: console.name,
                    font: .boldSystemFont(ofSize: 18),
                    leftFade: 10,
                    rightFade: 10,
                    startDelay: 1,
                    alignment: .leading
                )
                
                if console.active {
                    Text("Active System")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        // Helps the separator line up nicely with the text
        .alignmentGuide(.listRowSeparatorLeading) { d in d[.leading] + 56 }
    }
}

struct ConsoleGridItemView: View {
    var console: Console
    
    var body: some View {
        VStack(spacing: 12) {
            // Larger Icon for the grid
            KFImage(URL(string: console.iconURL))
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .padding(10)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Text(console.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 40, alignment: .top)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let mockConsole = Console(id: 1, name: "Nintendo Entertainment System", iconURL: "https://retroachievements.org/static/img/console/1.png", active: true, isGameSystem: true)
    
    return List {
        ConsoleDetailView(console: mockConsole, hardcoreMode: $hardcoreMode)
    }
}
