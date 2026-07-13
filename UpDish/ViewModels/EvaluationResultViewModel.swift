//
//  EvaluationResultViewModel.swift
//  UpDish
//
//  Owns the state of the Detail Isi Piringku screen.
//
//  Verdict: deterministic, computed up front.
//  Feedback + recommendations: two on-device stages kicked off by `load()` —
//    1. the Foundation Model writes them in English, then
//    2. `.translationTask` in the View calls `translate(using:)` to convert to
//       Indonesian.
//  Until both finish, deterministic Indonesian fallbacks are shown.
//

import SwiftUI
#if canImport(Translation)
import Translation
#endif

@MainActor
@Observable
final class EvaluationResultViewModel {
    let foodName: String
    let dateText: String
    let imageAssetName: String?

    let evaluation: MealEvaluation

    var feedback: FeedbackText
    var recommendation: MealRecommendation?
    private(set) var isGeneratingGuidance = false

    private let guidanceService: MealGuidanceService
    private var pendingEnglish: EnglishGuidance?

    #if canImport(Translation)
    /// Set once English guidance is ready; drives the View's `.translationTask`.
    var translationConfig: TranslationSession.Configuration?
    #endif

    init(
        foodName: String,
        components: [MealComponent],
        date: Date = .now,
        imageAssetName: String? = nil,
        evaluationService: IsiPiringkuEvaluationService = .init(),
        guidanceService: MealGuidanceService = .init()
    ) {
        self.foodName = foodName
        self.dateText = DateFormatterHelper.mealTimestamp(from: date)
        self.imageAssetName = imageAssetName
        self.guidanceService = guidanceService

        let evaluation = evaluationService.evaluate(mealName: foodName, components: components)
        self.evaluation = evaluation

        let fallback = guidanceService.fallbackGuidance(for: evaluation)
        self.feedback = fallback.feedback
        self.recommendation = fallback.recommendation
    }

    /// Stage 1: get English guidance from the on-device model, then trigger
    /// translation. Keeps the deterministic fallback if the model is absent.
    func load() async {
        isGeneratingGuidance = true

        guard let english = await guidanceService.makeEnglishGuidance(for: evaluation) else {
            isGeneratingGuidance = false
            return
        }
        pendingEnglish = english

        #if canImport(Translation)
        translationConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "id")
        )
        #else
        isGeneratingGuidance = false
        #endif
    }

    #if canImport(Translation)
    /// Stage 2: translate the English guidance into Indonesian and publish it.
    func translate(using session: TranslationSession) async {
        defer { isGeneratingGuidance = false }
        guard let english = pendingEnglish else { return }

        do {
            let body = try await session.translate(english.feedbackBody).targetText
            let summary = english.recommendationSummary.isEmpty
                ? ""
                : try await session.translate(english.recommendationSummary).targetText

            var translatedOptions: [(category: FoodCategory, text: String)] = []
            for suggestion in english.suggestions where !suggestion.text.isEmpty {
                let text = try await session.translate(suggestion.text).targetText
                translatedOptions.append((suggestion.category, text))
            }

            feedback = FeedbackText(headline: evaluation.overallStatus.displayName, body: body)
            if let recommendation = guidanceService.recommendation(
                summary: summary,
                options: translatedOptions,
                for: evaluation
            ) {
                self.recommendation = recommendation
            }
        } catch {
            NSLog("UPDISH translation error: \(error)")
            // Keep the Indonesian deterministic fallback already on screen.
        }
    }
    #endif
}
