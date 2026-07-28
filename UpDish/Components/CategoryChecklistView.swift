//
//  CategoryChecklistView.swift
//  UpDish
//
//  The four Isi Piringku groups with a status icon each — the list beside
//  the plate visual.
//

import SwiftUI

struct CategoryChecklistView: View {
    let evaluations: [CategoryEvaluation]
    /// While the AI runs, each group shows a spinner in place of its verdict.
    var isLoading: Bool = false

    /// 20pt at the default text size, but grows with Dynamic Type so the icon
    /// stays proportional to the label instead of shrinking beside large text.
    @ScaledMetric private var iconSize: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(evaluations) { evaluation in
                // Top-aligned so a big icon lines up with the first line when
                // the label wraps at large text sizes.
                HStack(alignment: .top, spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: iconSize, height: iconSize)
                    } else {
                        Image(systemName: icon(for: evaluation.status).iconName)
                            .foregroundStyle(icon(for: evaluation.status).iconColor)
                            .font(.system(size: iconSize))
                    }
                    Text(evaluation.category.checklistName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                // Read as one phrase — "Makanan Pokok sudah sesuai" — instead of
                // announcing the tick/cross symbol and the name separately.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    isLoading
                        ? "\(evaluation.category.checklistName), sedang dianalisis"
                        : "\(evaluation.category.checklistName) \(spokenStatus(for: evaluation.status))"
                )
            }
        }
    }

    /// The checklist is binary: green check only when the group is fully
    /// sufficient, red cross otherwise (both "sedikit" and "tidak ada"). The
    /// difference between kurang and missing is explained in the feedback
    /// paragraph, not with a separate (yellow) icon.
    private func icon(for status: CategoryStatus) -> CategoryStatus {
        status == .sufficient ? .sufficient : .missing
    }

    /// Spoken equivalent of the tick / cross, matching the binary the icon shows.
    private func spokenStatus(for status: CategoryStatus) -> String {
        status == .sufficient ? "sudah sesuai" : "belum sesuai"
    }
}

#Preview {
    CategoryChecklistView(
        evaluations: [
            CategoryEvaluation(category: .stapleFood, portionPercentage: 34, status: .sufficient, targetPercentage: FoodCategory.stapleFood.targetPercentage),
            CategoryEvaluation(category: .protein, portionPercentage: 16, status: .sufficient, targetPercentage: FoodCategory.protein.targetPercentage),
            CategoryEvaluation(category: .vegetable, portionPercentage: 34, status: .sufficient, targetPercentage: FoodCategory.vegetable.targetPercentage),
            CategoryEvaluation(category: .fruit, portionPercentage: 0, status: .missing, targetPercentage: FoodCategory.fruit.targetPercentage)
        ]
    )
    .padding()
}
