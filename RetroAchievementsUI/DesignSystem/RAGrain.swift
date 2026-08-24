//
//  RAGrain.swift
//  RetroAchievementsUI
//
//  Paper-grain overlay for card stock.
//
//  The noise tile is generated once and reused. Generating noise per card (or
//  worse, per redraw) would make a scrolling grid stutter.
//

import SwiftUI
import UIKit

enum RAGrain {

    static let tileSize: CGFloat = 96

    /// Monochrome noise, generated once on first use.
    static let tile: UIImage = makeTile()

    private static func makeTile() -> UIImage {
        let side = Int(tileSize)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(
            size: CGSize(width: tileSize, height: tileSize),
            format: format
        ).image { context in
            let cg = context.cgContext
            // Deterministic so the texture is identical every launch.
            var seed: UInt64 = 0x9E3779B97F4A7C15

            for y in 0..<side {
                for x in 0..<side {
                    seed ^= seed << 13
                    seed ^= seed >> 7
                    seed ^= seed << 17
                    let value = CGFloat(seed % 255) / 255.0
                    cg.setFillColor(UIColor(white: value, alpha: 1).cgColor)
                    cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
    }
}

struct RAGrainOverlay: View {
    var opacity: Double = 0.055

    var body: some View {
        Image(uiImage: RAGrain.tile)
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}
