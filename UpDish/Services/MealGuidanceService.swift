//
//  MealGuidanceService.swift
//  UpDish
//
//  Produces the feedback text and the recommendations for a meal.
//
//  Because Apple's on-device model does NOT support Indonesian, the pipeline
//  is two on-device stages:
//    1. The Foundation Model reasons about the dish and writes guidance in
//       ENGLISH (see the +FoundationModels extension).
//    2. Apple's Translation framework translates that English into Bahasa
//       Indonesia (driven from the View via `.translationTask`).
//
//  If either stage is unavailable, the deterministic Indonesian fallback
//  (template feedback + curated recommendation DB) is used. The verdict itself
//  always stays deterministic in IsiPiringkuEvaluationService.
//

import Foundation

struct MealGuidance {
    let feedback: FeedbackText
    let recommendation: MealRecommendation?
}

/// Model output before translation. `text`/bodies are in English.
struct EnglishGuidance {
    let feedbackBody: String
    let recommendationSummary: String
    let suggestions: [EnglishSuggestion]
}

struct EnglishSuggestion {
    let category: FoodCategory
    let text: String
}

struct MealGuidanceService {
    var feedbackService = FeedbackService()
    var recommendationService = RecommendationService()

    /// Instant, deterministic Indonesian guidance so the screen renders while
    /// the model + translation run.
    func fallbackGuidance(for evaluation: MealEvaluation) -> MealGuidance {
        MealGuidance(
            feedback: feedbackService.templateFeedback(for: evaluation),
            recommendation: recommendationService.recommendation(for: evaluation)
        )
    }

    /// Stage 1: English guidance from the on-device model. Nil when the model
    /// is unavailable (older devices) — caller keeps the deterministic fallback.
    func makeEnglishGuidance(for evaluation: MealEvaluation) async -> EnglishGuidance? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await generateEnglishGuidance(for: evaluation)
        }
        #endif
        return nil
    }

    /// Stage 2 assembly: turn already-translated Indonesian pieces into a
    /// MealRecommendation, gated to the groups the evaluation actually flagged.
    func recommendation(
        summary: String,
        options: [(category: FoodCategory, text: String)],
        for evaluation: MealEvaluation
    ) -> MealRecommendation? {
        let weakCategories = Set(evaluation.categoriesNeedingImprovement.map(\.category))
        guard !weakCategories.isEmpty else { return nil }

        var optionsByCategory: [FoodCategory: [RecommendationOption]] = [:]
        for option in options where weakCategories.contains(option.category) {
            guard let recommendationOption = Self.makeOption(from: option.text) else { continue }
            optionsByCategory[option.category, default: []].append(recommendationOption)
        }

        guard !optionsByCategory.isEmpty else { return nil }

        let groups = FoodCategory.plateOrder.compactMap { category -> RecommendationGroup? in
            guard let options = optionsByCategory[category], !options.isEmpty else { return nil }
            return RecommendationGroup(category: category, options: options)
        }

        return MealRecommendation(
            title: "Rekomendasi Perbaikan",
            message: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            groups: groups
        )
    }

    /// Splits a "Food — portion" suggestion into name + portion. Falls back to
    /// the whole string as the name when there is no separator.
    private static func makeOption(from text: String) -> RecommendationOption? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for separator in [" — ", " - ", "—", "-"] {
            if let range = trimmed.range(of: separator) {
                let name = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let portion = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    return RecommendationOption(name: name, portionDescription: portion)
                }
            }
        }
        return RecommendationOption(name: trimmed, portionDescription: "")
    }
}
