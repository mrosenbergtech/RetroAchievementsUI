//
//  AwardCardDetailView.swift
//  RetroAchievementsUI
//
//  One card, enlarged, with the foil sheen tracking device tilt — the closest
//  thing to holding it up to the light.
//

import SwiftUI

struct AwardCardDetailView: View {
    let card: AwardCardModel
    @Binding var hardcoreMode: Bool

    @EnvironmentObject var network: Network
    @Environment(\.dismiss) private var dismiss
    @Environment(\.selectedGameID) private var selectedGameID: Binding<GameSheetItem?>

    var body: some View {
        NavigationStack {
            List {
                Section {
                    RACardShowcase(face: .award(card, hardcoreMode: hardcoreMode),
                                   maxWidth: 300)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    detailRow("Award", card.tier.longDisplayName)
                    if let console = card.consoleName {
                        detailRow("Console", console)
                    }
                    if card.maxPossible > 0 {
                        detailRow("Achievements",
                                  "\(card.earned(hardcoreMode: hardcoreMode)) of \(card.maxPossible)")
                    }
                    if let date = card.awardedDateText {
                        detailRow("Awarded", date)
                    }
                }
                .listRowBackground(Color.raSurfaceRaised)

                if let gameID = card.gameID {
                    Section {
                        Button {
                            // Reuse the app's existing global game sheet.
                            // Requesting it in the same turn as dismiss() can
                            // drop the presentation, so hand off once this
                            // sheet has actually gone.
                            dismiss()
                            Task {
                                try? await Task.sleep(nanoseconds: 350_000_000)
                                selectedGameID.wrappedValue = GameSheetItem(id: gameID)
                            }
                        } label: {
                            Label("View Game", systemImage: "gamecontroller")
                                .font(.raTitle)
                                .foregroundStyle(Color.raAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(Color.raSurfaceRaised)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.raSurface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.raBody)
                .foregroundStyle(Color.raTextSecondary)
            Spacer()
            Text(value)
                .font(.raBody.weight(.semibold))
                .foregroundStyle(Color.raTextPrimary)
        }
    }
}
