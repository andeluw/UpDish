//
//  RecommendationCard.swift
//  UpDish
//
//  Shows the improvement suggestion: a narrative line plus one or more
//  groups of concrete options, separated by a dashed divider (matching the
//  "Perlu Diperbaiki" mockup). Rendered only when a Recommendation exists.
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: MealRecommendation
    let status: MealBalanceStatus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wand.and.sparkles.inverse")
                .foregroundStyle(.primary)
                .font(.system(size: 20))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .accessibilityLabel(recommendation.title)

                Text(recommendation.message)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(recommendation.message)

                ForEach(recommendation.groups) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(header(for: group))
                            .font(.subheadline)
                            .accessibilityLabel(header(for: group))
                        ForEach(group.options) { option in
                            Text("• \(label(for: option))")
                                .font(.subheadline)
                                // Drops the bullet and the em dash, which are
                                // announced literally ("bullet", "dash").
                                .accessibilityLabel(spokenLabel(for: option))
                        }
                    }
                }

                if let closingNote {
                    Text(closingNote)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(closingNote)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Self.cardBorder, lineWidth: 2)
        )
    }

    private static let cardBackground = Color.white                                   // #FFFFFF
    private static let cardBorder = Color(red: 232 / 255, green: 224 / 255, blue: 211 / 255) // #E8E0D3

    /// "Pilih salah satu rekomendasi:" for a single group, or a per-group
    /// variant ("Pilih salah satu sayur rekomendasi:") when several groups need
    /// completing, so the lists don't run together.
    private func header(for group: RecommendationGroup) -> String {
        recommendation.groups.count > 1
            ? "Pilih salah satu \(group.category.displayName.lowercased()) rekomendasi:"
            : "Pilih salah satu rekomendasi:"
    }

    /// Shown only for a single group, where "lain" is unambiguous.
    private var closingNote: String? {
        guard recommendation.groups.count == 1,
              let group = recommendation.groups.first else { return nil }
        return "Boleh diganti dengan \(group.category.displayName.lowercased()) lain dengan porsi serupa."
    }

    private func label(for option: RecommendationOption) -> String {
        option.portionDescription.isEmpty
            ? option.name
            : "\(option.name) — \(option.portionDescription)"
    }

    /// Same content as `label(for:)` but punctuated for speech: a comma reads
    /// as a natural pause, where "•" and "—" are spoken as symbol names.
    private func spokenLabel(for option: RecommendationOption) -> String {
        option.portionDescription.isEmpty
            ? option.name
            : "\(option.name), \(option.portionDescription)"
    }
}

#Preview {
    RecommendationCard(
        recommendation: MealRecommendation(
            title: "Rekomendasi Perbaikan",
            message: "Tambahkan sayur untuk serat, vitamin, dan mineral. Jangan lupa buah untuk vitamin dan antioksidan.",
            groups: [
                RecommendationGroup(category: .vegetable, options: [
                    RecommendationOption(name: "Tumis Bayam", portionDescription: "1 porsi sedang"),
                    RecommendationOption(name: "Capcay / Sayur Bening", portionDescription: "1 porsi sedang")
                ]),
                RecommendationGroup(category: .fruit, options: [
                    RecommendationOption(name: "Pepaya", portionDescription: "1 potong sedang"),
                    RecommendationOption(name: "Pisang", portionDescription: "1 buah sedang")
                ])
            ]
        ),
        status: .needsImprovement
    )
    .padding()
}
