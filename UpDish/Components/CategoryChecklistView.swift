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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(evaluations) { evaluation in
                HStack(spacing: 10) {
                    Image(systemName: icon(for: evaluation.status).iconName)
                        .foregroundStyle(icon(for: evaluation.status).iconColor)
                        .font(.system(size: 20))
                    Text(evaluation.category.checklistName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
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
