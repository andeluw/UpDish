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
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(status.accentColor)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 10) {
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundStyle(status.accentColor)

                Text(recommendation.message)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(recommendation.groups.enumerated()), id: \.element.id) { index, group in
                    if index > 0 {
                        DashedDivider()
                            .foregroundStyle(status.accentColor.opacity(0.6))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(group.options) { option in
                            Text("• \(label(for: option))")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(status.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func label(for option: RecommendationOption) -> String {
        option.portionDescription.isEmpty
            ? option.name
            : "\(option.name) — \(option.portionDescription)"
    }
}

/// A thin dashed horizontal line.
private struct DashedDivider: View {
    var body: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .frame(height: 1)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
            return path
        }
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
