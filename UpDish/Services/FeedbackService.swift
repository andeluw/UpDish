//
//  FeedbackService.swift
//  UpDish
//
//  Deterministic, number-free feedback text. This is the FALLBACK used when
//  the on-device model is unavailable — the primary feedback comes from
//  MealGuidanceService via Foundation Models + translation.
//

import Foundation

/// The text rendered in the feedback card.
struct FeedbackText {
    let headline: String
    let body: String
}

struct FeedbackService {

    func templateFeedback(for evaluation: MealEvaluation) -> FeedbackText {
        let missing = evaluation.categoryEvaluations
            .filter { !$0.status.isPresent }
            .map { $0.category.displayName.lowercased() }

        switch evaluation.overallStatus {
        case .balanced:
            return FeedbackText(
                headline: evaluation.overallStatus.displayName,
                body: "Komposisi makananmu sudah seimbang. Pertahankan, ya!"
            )
        case .mostlyBalanced:
            let lack = missing.first ?? "buah"
            return FeedbackText(
                headline: evaluation.overallStatus.displayName,
                body: "Komposisi makanan sudah cukup seimbang, tinggal lengkapi dengan \(lack)."
            )
        case .needsImprovement:
            return FeedbackText(
                headline: evaluation.overallStatus.displayName,
                body: "Komposisi makanan belum seimbang. Yuk, lengkapi dengan sayur dan buah."
            )
        }
    }
}
