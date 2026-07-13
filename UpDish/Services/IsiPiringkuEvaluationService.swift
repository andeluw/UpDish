//
//  IsiPiringkuEvaluationService.swift
//  UpDish
//
//  The deterministic heart of the app: turns detected components (with their
//  portion percentages) into a per-category status and an overall verdict.
//  Kept out of the AI on purpose — the verdict must be reliable and
//  repeatable, and it gates the recommendations.
//

import Foundation

struct IsiPiringkuEvaluationService {

    func evaluate(mealName: String, components: [MealComponent]) -> MealEvaluation {
        let evaluations = FoodCategory.plateOrder.map { category -> CategoryEvaluation in
            let portion = components
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.portionPercentage }
            return CategoryEvaluation(
                category: category,
                portionPercentage: portion,
                status: status(portion: portion, target: category.targetPercentage),
                targetPercentage: category.targetPercentage
            )
        }

        let needingImprovement = evaluations.filter { $0.status.needsImprovement }.count
        let overall = overallStatus(needingImprovement: needingImprovement)

        return MealEvaluation(
            mealName: mealName,
            components: components,
            categoryEvaluations: evaluations,
            overallStatus: overall,
            summary: summary(for: overall)
        )
    }

    // MARK: - Per-category status

    private func status(portion: Int, target: Double) -> CategoryStatus {
        if portion == 0 { return .missing }
        // Below the recommended share of the plate → present but too little.
        return Double(portion) < target ? .insufficient : .sufficient
    }

    // MARK: - Overall verdict

    private func overallStatus(needingImprovement: Int) -> MealBalanceStatus {
        switch needingImprovement {
        case 0: .balanced
        case 1: .mostlyBalanced
        default: .needsImprovement
        }
    }

    private func summary(for status: MealBalanceStatus) -> String {
        switch status {
        case .balanced:
            "Komposisi makanan sudah seimbang sesuai Isi Piringku."
        case .mostlyBalanced:
            "Komposisi makanan sudah cukup seimbang, tinggal sedikit dilengkapi."
        case .needsImprovement:
            "Komposisi makanan belum seimbang dan perlu dilengkapi."
        }
    }
}
