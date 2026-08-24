//
//  ConsoleDetailView.swift
//  RetroAchievementsUI
//
//  Console rows and grid cells.
//

import SwiftUI
import Kingfisher

struct ConsoleDetailView: View {
    var console: Console
    @Binding var hardcoreMode: Bool

    var body: some View {
        HStack(spacing: 14) {
            ConsoleIcon(console: console, size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(console.name)
                    .font(.raNameplate)
                    .foregroundStyle(Color.raTextPrimary)
                    .lineLimit(2)

                if console.active {
                    Text("Active system")
                        .font(.raNameplateSub)
                        .foregroundStyle(.green)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
}

/// Console icons are transparent logos on no background, so they get a plate to
/// sit on rather than the cropped-fill treatment game art uses.
struct ConsoleIcon: View {
    var console: Console
    var size: CGFloat = 42

    var body: some View {
        KFImage(URL(string: console.iconURL))
            .resizable()
            .placeholder {
                Image(systemName: "gamecontroller")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(Color.raTextTertiary)
            }
            .fade(duration: 0.2)
            .aspectRatio(contentMode: .fit)
            .padding(size * 0.16)
            .frame(width: size, height: size)
            .background(Color.raSurfaceSunken)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    }
}

/// Grid cell for the Consoles tab.
struct ConsoleGridItemView: View {
    var console: Console

    var body: some View {
        VStack(spacing: 10) {
            ConsoleIcon(console: console, size: 76)

            Text(console.name)
                .font(.raNameplateSub.weight(.semibold))
                .foregroundStyle(Color.raTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(height: 30, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(Color.raSurfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
    }
}

#Preview {
    @Previewable @State var hardcoreMode: Bool = true
    let mockConsole = Console(id: 2, name: "Nintendo 64",
                              iconURL: "https://static.retroachievements.org/assets/images/system/n64.png",
                              active: true, isGameSystem: true)

    return VStack(spacing: 20) {
        List {
            ConsoleDetailView(console: mockConsole, hardcoreMode: $hardcoreMode)
        }
        .frame(height: 120)

        HStack(spacing: 12) {
            ConsoleGridItemView(console: mockConsole)
            ConsoleGridItemView(console: mockConsole)
        }
        .padding()
    }
    .background(Color.raSurface)
}
