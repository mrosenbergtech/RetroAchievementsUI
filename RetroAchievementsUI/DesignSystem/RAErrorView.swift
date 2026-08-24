//
//  RAErrorView.swift
//  RetroAchievementsUI
//
//  Shown when a screen has nothing to display and a failure explains why.
//
//  Previously these cases were invisible: a revoked key, an outage and "you
//  haven't played anything yet" all rendered the same empty state, with no way
//  to try again.
//

import SwiftUI

struct RAErrorView: View {
    let error: RANetworkError
    var retry: (() async -> Void)?
    /// Offered instead of a retry when the fix is in Settings.
    var openSettings: (() -> Void)?

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: error.systemImage)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.raTextTertiary)

            VStack(spacing: 6) {
                Text(error.title)
                    .font(.raTitle)
                    .foregroundStyle(Color.raTextPrimary)
                Text(error.message)
                    .font(.raBody)
                    .foregroundStyle(Color.raTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            if error.requiresSignIn, let openSettings {
                Button("Open Settings", action: openSettings)
                    .buttonStyle(.borderedProminent)
                    .tint(.raAccent)
            } else if error.isWorthRetrying, let retry {
                Button {
                    Task {
                        isRetrying = true
                        await retry()
                        isRetrying = false
                    }
                } label: {
                    if isRetrying {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Try Again")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.raAccent)
                .disabled(isRetrying)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}

/// Slim banner for when a screen already has content but a refresh failed —
/// the stale data stays useful, so this reports the problem without taking the
/// screen over.
struct RAErrorBanner: View {
    let error: RANetworkError
    var retry: (() async -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: error.systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(error.title)
                .font(.raCaption.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 4)

            if error.isWorthRetrying, let retry {
                Button("Retry") { Task { await retry() } }
                    .font(.raCaption.weight(.bold))
                    .buttonStyle(.plain)
            }
        }
        .foregroundStyle(Color.raTextPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.raSeparator, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 3)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview("Full") {
    RAErrorView(error: .offline, retry: {})
        .background(Color.raSurface)
}

#Preview("Unauthorized") {
    RAErrorView(error: .unauthorized, openSettings: {})
        .background(Color.raSurface)
}

#Preview("Banner") {
    VStack {
        RAErrorBanner(error: .timedOut, retry: {})
        Spacer()
    }
    .background(Color.raSurface)
}
