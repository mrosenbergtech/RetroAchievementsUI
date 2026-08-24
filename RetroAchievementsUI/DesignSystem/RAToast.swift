//
//  RAToast.swift
//  RetroAchievementsUI
//
//  Transient confirmation banner. Moved out of Views/Sub/ToastView.swift so it
//  sits with the rest of the shared components.
//

import SwiftUI

struct ToastView: View {
    let message: String
    var systemImage: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(.raBody.weight(.semibold))
        }
        .foregroundStyle(Color.raTextPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.raSeparator, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .padding(.bottom, 28)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String,
               systemImage: String = "checkmark.circle.fill") -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, systemImage: systemImage))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let systemImage: String

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isShowing {
                ToastView(message: message, systemImage: systemImage)
                    // A cancellable task rather than DispatchQueue.asyncAfter:
                    // re-showing the toast used to stack timers, so the second
                    // one could dismiss the banner early.
                    .task(id: message) {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        guard !Task.isCancelled else { return }
                        withAnimation { isShowing = false }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isShowing)
    }
}

#Preview {
    Color.raSurface
        .toast(isShowing: .constant(true), message: "Game library synchronised")
}
