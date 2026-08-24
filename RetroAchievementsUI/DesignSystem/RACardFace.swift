//
//  RACardFace.swift
//  RetroAchievementsUI
//
//  The trading-card face, shared by every card in the app.
//
//  Anatomy, top to bottom:
//      metal frame  →  art window  →  nameplate  →  rule  →  stat block
//
//  Awards, games and achievements all render through this so a card is a card
//  wherever it appears. What varies is the material (frame metal and stock) and
//  the tagline — never the geometry, because a mixed row of cards has to line
//  up as one set.
//

import SwiftUI
import Kingfisher

enum RACardMetrics {
    /// Real trading card proportions (2.5" × 3.5").
    static let aspectRatio: CGFloat = 2.5 / 3.5
    static let cornerRadius: CGFloat = 12
    static let frameWidth: CGFloat = 3
    static let innerCornerRadius: CGFloat = 6
    /// Cards below this width drop the nameplate's secondary line.
    static let compactWidthThreshold: CGFloat = 118

    // Vertical zones as fractions of the card's inner height.
    static let artFraction: CGFloat = 0.56
    static let nameplateFraction: CGFloat = 0.28
    static let statFraction: CGFloat = 0.155

    /// Standard card width in carousels and grids.
    static let carouselWidth: CGFloat = 138

    /// Height a carousel row needs for a given card width.
    ///
    /// A horizontal ScrollView inside a List row has no intrinsic height to
    /// offer, so the row has to be told.
    static func carouselHeight(for width: CGFloat = carouselWidth) -> CGFloat {
        width / aspectRatio + 4      // + the carousel's vertical padding
    }
}

/// Everything a card face needs to draw itself.
struct RACardFace {
    var artPath: String?
    /// Achievement badges are transparent PNGs sized for their own frame, so
    /// they fill the emblem rather than sitting inset like a game icon.
    var artIsBadge: Bool = false
    var placeholderSymbol: String = "gamecontroller"

    var title: String
    var subtitle: String?

    /// Bottom-left label: "MASTERED", "UNBEATEN", "UNLOCKED"…
    var tagline: String
    /// Bottom-right figure: "44/56", points, a date.
    var trailingStat: String?

    var material: RarityMaterial
    /// Locked achievements recede without disappearing.
    var dimmed: Bool = false

    var accessibilityLabel: String {
        [title, tagline, subtitle, trailingStat]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

struct RACardFaceView: View {
    let face: RACardFace
    /// 0…1 position of the foil sheen band. Only used on foil materials.
    var foilPhase: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var material: RarityMaterial { face.material }

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < RACardMetrics.compactWidthThreshold
            let inset = RACardMetrics.frameWidth + 2
            let inner = geo.size.height - inset * 2

            // Zones are allocated as fractions of the card, not by intrinsic
            // content size — a two-line title must never push the stat block
            // off the card.
            VStack(spacing: 0) {
                artWindow(height: inner * RACardMetrics.artFraction)
                nameplate(compact: isCompact)
                    .frame(height: inner * RACardMetrics.nameplateFraction)
                Divider()
                    .overlay(Color.raCardRule)
                    .padding(.horizontal, 10)
                statBlock
                    .frame(height: inner * RACardMetrics.statFraction)
            }
            .padding(inset)
            .background(stock)
            .overlay(RAGrainOverlay())
            .overlay(foilSheen)
            .overlay(bevel)
            .overlay(metalFrame)
            .clipShape(RoundedRectangle(cornerRadius: RACardMetrics.cornerRadius, style: .continuous))
            .opacity(face.dimmed ? 0.72 : 1)
        }
        .aspectRatio(RACardMetrics.aspectRatio, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(face.accessibilityLabel)
    }

    // MARK: - Art

    /// The artwork, presented as an emblem inset into a recessed plate.
    ///
    /// RA icons and badges are only ~96px, so the emblem is capped near its
    /// native size rather than stretched to fill the window.
    private func artWindow(height: CGFloat) -> some View {
        let emblem = min(height * (face.artIsBadge ? 0.80 : 0.72), 68)

        return ZStack {
            RoundedRectangle(cornerRadius: RACardMetrics.innerCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(colors: [.black.opacity(0.45), .black.opacity(0.22)],
                                   startPoint: .top, endPoint: .bottom)
                )

            // Ambient wash of the same artwork, heavily blurred.
            //
            // The emblem is deliberately capped near its native ~96px so it
            // stays crisp, which left a large empty plate on bigger cards. This
            // fills it with colour drawn from the art itself; the blur is the
            // point, so upscaling costs nothing.
            KFImage(RAImageURL.gameIcon(face.artPath))
                .resizable()
                .fade(duration: 0.2)
                .aspectRatio(contentMode: .fill)
                .blur(radius: 26, opaque: false)
                .opacity(0.45)
                .overlay(Color.black.opacity(0.25))
                .allowsHitTesting(false)

            KFImage(RAImageURL.gameIcon(face.artPath))
                .resizable()
                .placeholder {
                    Image(systemName: face.placeholderSymbol)
                        .font(.system(size: emblem * 0.42, weight: .light))
                        .foregroundStyle(material.ink.opacity(0.30))
                }
                .fade(duration: 0.2)
                .aspectRatio(contentMode: .fit)
                .frame(width: emblem, height: emblem)
                .clipShape(RoundedRectangle(cornerRadius: emblem * 0.18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: emblem * 0.18, style: .continuous)
                        .strokeBorder(material.bevelHighlight.opacity(0.18), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: RACardMetrics.innerCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RACardMetrics.innerCornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Nameplate

    private func nameplate(compact: Bool) -> some View {
        VStack(spacing: 1) {
            Spacer(minLength: 0)

            Text(face.title)
                .font(.raNameplate)
                .foregroundStyle(Color.raCardPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !compact, let subtitle = face.subtitle {
                Text(subtitle)
                    .font(.raNameplateSub)
                    .foregroundStyle(Color.raCardSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 7)
    }

    // MARK: - Stat block

    private var statBlock: some View {
        HStack(spacing: 3) {
            Text(face.tagline)
                .font(.raMicro)
                .tracking(0.4)
                .foregroundStyle(material.ink)
                // The tagline is the card's classification, so it wins the
                // space fight — on a narrow grid card "UNBEATEN" was being
                // truncated to "UNBEAT…" while the count kept its full width.
                .layoutPriority(1)

            Spacer(minLength: 2)

            if let stat = face.trailingStat {
                Text(stat)
                    .font(.raStatSmall)
                    .foregroundStyle(Color.raCardSecondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .padding(.horizontal, 7)
    }

    // MARK: - Materials

    private var stock: some View {
        LinearGradient(colors: material.stock, startPoint: .top, endPoint: .bottom)
    }

    /// An angular gradient gives the multi-stop light/dark alternation that
    /// reads as brushed metal; a linear one just looks like a coloured outline.
    private var metalFrame: some View {
        RoundedRectangle(cornerRadius: RACardMetrics.cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(colors: material.metal, center: .center),
                lineWidth: RACardMetrics.frameWidth
            )
    }

    private var bevel: some View {
        RoundedRectangle(cornerRadius: RACardMetrics.cornerRadius - RACardMetrics.frameWidth,
                         style: .continuous)
            .strokeBorder(material.bevelHighlight.opacity(0.22), lineWidth: 1)
            .padding(RACardMetrics.frameWidth)
    }

    @ViewBuilder
    private var foilSheen: some View {
        if material.isFoil && !reduceMotion {
            GeometryReader { geo in
                let width = geo.size.width
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.35),
                        .init(color: .white.opacity(material.foilIntensity), location: 0.5),
                        .init(color: .clear, location: 0.65),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: width * 2)
                .offset(x: -width + (foilPhase * width * 2))
                .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Cell

/// A card with the one-shot sheen sweep used in carousels and grids.
struct RACardCell: View {
    let face: RACardFace

    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RACardFaceView(face: face, foilPhase: phase)
            .onAppear {
                guard !reduceMotion, face.material.isFoil else { return }
                // A single sweep on first appearance. Looping this for every
                // cell in a scrolling grid would be distracting and expensive.
                withAnimation(.easeInOut(duration: 1.1).delay(0.15)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Carousel

/// The horizontal deck used for Awards, Recently Played and Recent Achievements.
///
/// Snaps to card boundaries and lets neighbours recede, so it reads as a deck
/// being flicked through rather than a strip sliding past.
struct RACardCarousel<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var width: CGFloat = RACardMetrics.carouselWidth
    @ViewBuilder var content: (Item) -> Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(items) { item in
                    content(item)
                        .frame(width: width)
                        .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                            view
                                .scaleEffect(phase.isIdentity ? 1 : 0.90)
                                .opacity(phase.isIdentity ? 1 : 0.55)
                                .rotation3DEffect(
                                    .degrees(phase.value * -6),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.5
                                )
                        }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
}
