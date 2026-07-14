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

    var feedback: FeedbackText?
    var recommendation: MealRecommendation?
    /// True while the AI pipeline (model + translation) is still running. The
    /// screen shows a loading indicator during this time — never the fallback.
    private(set) var isGeneratingGuidance = true

    /// Which stage produced the text currently on screen. Lets us tell, at a
    /// glance, whether we're seeing the deterministic fallback, the raw English
    /// model output, or the fully translated result. Surfaced as a DEBUG badge.
    enum GuidanceSource: String {
        case fallback = "Fallback template (ID)"
        case foundationModel = "Foundation Model (EN, not translated)"
        case translated = "Foundation Model → Translated (ID)"

        /// Higher = further along the pipeline. Guidance only ever moves forward.
        var rank: Int {
            switch self {
            case .fallback: 0
            case .foundationModel: 1
            case .translated: 2
            }
        }
    }
    private(set) var guidanceSource: GuidanceSource = .fallback

    /// Advances the badge only forward. `.translationTask` / `.task` can re-fire
    /// out of order once translation is fast (assets cached), so a late
    /// `.foundationModel` write must never clobber `.translated`.
    private func advanceGuidance(to source: GuidanceSource) {
        guard source.rank > guidanceSource.rank else { return }
        guidanceSource = source
    }

    private var hasLoaded = false
    private let guidanceService: MealGuidanceService
    private var pendingEnglish: EnglishGuidance?
    /// Deterministic Indonesian guidance, shown only if the AI pipeline can't
    /// deliver (model unavailable or translation fails) — never during loading.
    private let fallback: MealGuidance

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

        self.fallback = guidanceService.fallbackGuidance(for: evaluation)
        // Start empty + loading; content appears once the AI pipeline resolves.
        self.feedback = nil
        self.recommendation = nil
    }

    /// Stage 1: get English guidance from the on-device model, then trigger
    /// translation. Keeps the deterministic fallback if the model is absent.
    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        #if canImport(Translation)
        // One-time diagnostic: dump every language Apple Translation supports on
        // THIS device, and whether Indonesian is among them. Settles whether the
        // EN→ID translation approach is viable at all.
        let supported = await LanguageAvailability().supportedLanguages
        let codes = supported.map { $0.languageCode?.identifier ?? "?" }.sorted()
        let hasIndonesian = supported.contains { $0.languageCode?.identifier == "id" }
        NSLog("UPDISH_TRANSLATE_SUPPORTED (\(codes.count)): \(codes.joined(separator: ", "))")
        NSLog("UPDISH_TRANSLATE_HAS_INDONESIAN: \(hasIndonesian)")
        #endif

        guard let english = await guidanceService.makeEnglishGuidance(for: evaluation) else {
            NSLog("UPDISH_STAGE1_FM: no output — showing deterministic fallback (model unavailable)")
            applyFallback()
            return
        }
        pendingEnglish = english
        advanceGuidance(to: .foundationModel)
        NSLog("UPDISH_STAGE1_FM: got English guidance → \"\(english.feedbackBody)\"")

        #if canImport(Translation)
        translationConfig = TranslationSession.Configuration(
            source: Locale.Language(identifier: "en"),
            target: Locale.Language(identifier: "id")
        )
        #else
        // No on-device translation on this platform — fall back to templates.
        applyFallback()
        #endif
    }

    /// Publishes the deterministic Indonesian guidance and ends the loading
    /// state. Used only when the model or the translator can't deliver.
    private func applyFallback() {
        feedback = fallback.feedback
        recommendation = fallback.recommendation
        isGeneratingGuidance = false
    }

    #if canImport(Translation)
    /// Stage 2: translate the English guidance into Indonesian and publish it.
    func translate(using session: TranslationSession) async {
        // Already translated? A re-fired task must not redo work or reset state.
        guard guidanceSource != .translated, let english = pendingEnglish else { return }

        do {
            NSLog("UPDISH_STAGE2_TRANSLATE: preparing translation (ensures en→id assets are downloaded)")
            // Warms up the translation extension and downloads the en→id language
            // pack if needed. Skipping this makes translate() fail with a dropped
            // connection (TranslationErrorDomain Code=14) when assets aren't ready.
            try await session.prepareTranslation()

            NSLog("UPDISH_STAGE2_TRANSLATE: starting EN→ID translation")
            let body = try await session.translate(english.feedbackBody).targetText
            let summary = english.recommendationSummary.isEmpty
                ? ""
                : try await session.translate(english.recommendationSummary).targetText

            var translatedOptions: [(category: FoodCategory, text: String)] = []
            for suggestion in english.suggestions where !suggestion.text.isEmpty {
                let text = try await session.translate(suggestion.text).targetText
                translatedOptions.append((suggestion.category, text))
            }

            // Both the feedback AND the recommendation come from the model, now
            // in Indonesian. Fall back to the curated recommendation only if the
            // model produced no usable options for the flagged groups.
            feedback = FeedbackText(headline: evaluation.overallStatus.displayName, body: body)
            recommendation = guidanceService.recommendation(
                summary: summary,
                options: translatedOptions,
                for: evaluation
            ) ?? fallback.recommendation

            pendingEnglish = nil
            advanceGuidance(to: .translated)
            isGeneratingGuidance = false
            NSLog("UPDISH_STAGE2_TRANSLATE: success → \"\(body)\"")
        } catch {
            NSLog("UPDISH_STAGE2_TRANSLATE: FAILED (\(error)) — showing deterministic fallback")
            applyFallback()
        }
    }
    #endif
}
