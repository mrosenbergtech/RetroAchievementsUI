//
//  ToastView.swift
//  RetroAchievementsUI
//
//  Created by Michael Rosenberg on 1/9/26.
//

import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.9))
                    .shadow(radius: 4)
            )
            .padding(.bottom, 30)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        ZStack(alignment: .bottom) {
            self
            if isShowing.wrappedValue {
                ToastView(message: message)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isShowing.wrappedValue = false
                            }
                        }
                    }
            }
        }
    }
}
