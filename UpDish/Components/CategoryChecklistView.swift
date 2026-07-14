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
                    Image(systemName: evaluation.status.iconName)
                        .foregroundStyle(evaluation.status.iconColor)
                        .font(.system(size: 20))
                    Text(evaluation.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
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
