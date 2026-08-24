//
//  RACardShowcase.swift
//  RetroAchievementsUI
//
//  A card presented large, as the subject of a screen rather than one of many
//  in a deck: it tilts with the device and catches the light, which is the
//  closest thing to holding it up.
//
//  Shared by the award card detail and the achievement detail, so "the big
//  card" is defined once.
//

import SwiftUI
import CoreMotion

struct RACardShowcase: View {
    let face: RACardFace
    var maxWidth: CGFloat = 280

    @StateObject private var tilt = TiltReader()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RACardFaceView(face: face, foilPhase: reduceMotion ? 0.5 : tilt.phase)
            .frame(maxWidth: maxWidth)
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : tilt.roll * 6),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : tilt.pitch * -4),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.6
            )
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
            .frame(maxWidth: .infinity)
            .onAppear { if !reduceMotion { tilt.start() } }
            .onDisappear { tilt.stop() }
    }
}

// MARK: - Motion

/// Publishes normalized device tilt for the foil sheen and parallax.
///
/// Kept deliberately small: 30 Hz, stopped the moment the view disappears, and
/// never started at all under Reduce Motion.
@MainActor
final class TiltReader: ObservableObject {
    /// -1…1
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    /// 0…1, drives the sheen band's position across the card.
    @Published var phase: CGFloat = 0.5

    private let motion = CMMotionManager()

    func start() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            // Clamp to a shallow range — a small tilt should sweep the whole
            // card, and past ~35° the effect just pins to one edge.
            let roll = max(-1, min(1, data.attitude.roll / 0.6))
            let pitch = max(-1, min(1, data.attitude.pitch / 0.6))
            withAnimation(.linear(duration: 1.0 / 30.0)) {
                self.roll = roll
                self.pitch = pitch
                self.phase = CGFloat((roll + 1) / 2)
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }

    deinit {
        motion.stopDeviceMotionUpdates()
    }
}
