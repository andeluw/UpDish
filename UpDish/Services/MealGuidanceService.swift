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

/// Model output before translation. The model now writes ONLY the
/// recommendation food choices (in English); the feedback paragraph and the
/// recommendation summary are built deterministically from the evaluation.
struct EnglishGuidance {
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
        options: [(category: FoodCategory, text: String)],
        for evaluation: MealEvaluation
    ) -> MealRecommendation? {
        let weakCategories = Set(evaluation.categoriesNeedingImprovement.map(\.category))
        guard !weakCategories.isEmpty else { return nil }

        var optionsByCategory: [FoodCategory: [RecommendationOption]] = [:]
        for option in options {
            let name = Self.foodName(from: option.text)
            guard !name.isEmpty else { continue }

            // Trust the food NAME over the model's group label. The on-device
            // model mislabels foods (it filed "Tempe" as makanan pokok, which
            // then took the staple portion "1 centong"), so we classify the
            // name ourselves and fall back to the model's label only when the
            // name isn't recognised.
            let category = MealComponentClassifier.knownCategory(for: name) ?? option.category
            guard weakCategories.contains(category) else { continue }

            optionsByCategory[category, default: []].append(
                RecommendationOption(
                    name: name,
                    portionDescription: PortionGuide.portion(for: name, category: category)
                )
            )
        }

        guard !optionsByCategory.isEmpty else { return nil }

        let groups = FoodCategory.plateOrder.compactMap { category -> RecommendationGroup? in
            guard let options = optionsByCategory[category], !options.isEmpty else { return nil }
            return RecommendationGroup(category: category, options: options)
        }

        return MealRecommendation(
            title: "Rekomendasi Perbaikan",
            // Deterministic, category-accurate summary — names only the groups
            // that actually need completing, so it can never mention a group
            // that's already sufficient (as the model's own summary sometimes
            // did). The model supplies the food choices; the wording is ours.
            message: recommendationService.summary(for: evaluation),
            groups: groups
        )
    }

    /// Keeps only the food NAME from the model's "Food — portion" suggestion.
    /// The model's own portion is dropped on purpose: it was written in English
    /// and machine-translated, which is what produced wrong units like "nasi 1
    /// sendok". The portion is assigned separately from `PortionGuide`.
    private static func foodName(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        for separator in [" — ", " - ", "—", "-"] {
            if let range = trimmed.range(of: separator) {
                let candidate = String(trimmed[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
                if !candidate.isEmpty { return candidate }
            }
        }
        return trimmed
    }
}
