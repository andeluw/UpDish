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
import SwiftData
import UIKit
#if canImport(Translation)
import Translation
#endif

@MainActor
@Observable
final class EvaluationResultViewModel {
    let foodName: String
    let dateText: String
    /// Spoken form of `dateText`, which contains a "|" a screen reader would
    /// otherwise announce literally.
    let dateAccessibilityText: String
    let mealImage: UIImage?

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
    /// When set, AI guidance is cached here so reopening the same meal shows the
    /// identical text instead of the model regenerating a different response.
    private let modelContext: ModelContext?
    private var pendingEnglish: EnglishGuidance?
    /// Deterministic Indonesian guidance, shown only if the AI pipeline can't
    /// deliver (model unavailable or translation fails) — never during loading.
    private let fallback: MealGuidance

    #if canImport(Translation)
    /// Set once English guidance is ready; drives the View's `.translationTask`.
    var translationConfig: TranslationSession.Configuration?
    #endif

    /// Designated init: takes a ready-made evaluation (already produced by the
    /// deterministic `IsiPiringkuEvaluationService`). Used by the real flow,
    /// where the component screen runs the evaluation before navigating here.
    /// Services are passed as optionals rather than defaulted to `.init()`:
    /// default argument expressions are evaluated in a nonisolated context, and
    /// the project defaults types to `@MainActor`, so `= .init()` would warn.
    init(
        evaluation: MealEvaluation,
        mealImage: UIImage? = nil,
        modelContext: ModelContext? = nil,
        guidanceService: MealGuidanceService? = nil
    ) {
        let guidanceService = guidanceService ?? MealGuidanceService()

        self.foodName = evaluation.mealName
        self.dateText = DateFormatterHelper.mealTimestamp(from: evaluation.analyzedAt)
        self.dateAccessibilityText = DateFormatterHelper.spokenMealTimestamp(
            from: evaluation.analyzedAt
        )
        self.mealImage = mealImage
        self.modelContext = modelContext
        self.guidanceService = guidanceService
        self.evaluation = evaluation

        self.fallback = guidanceService.fallbackGuidance(for: evaluation)
        // Start empty + loading; content appears once the AI pipeline resolves.
        self.feedback = nil
        self.recommendation = nil
    }

    /// Convenience init: evaluates raw components first, then defers to the
    /// designated init. Used by previews and the sample-meal demo screen.
    convenience init(
        foodName: String,
        components: [MealComponent],
        mealImage: UIImage? = nil,
        modelContext: ModelContext? = nil,
        evaluationService: IsiPiringkuEvaluationService? = nil,
        guidanceService: MealGuidanceService? = nil
    ) {
        let evaluationService = evaluationService ?? IsiPiringkuEvaluationService()
        let evaluation = evaluationService.evaluate(mealName: foodName, components: components)
        self.init(
            evaluation: evaluation,
            mealImage: mealImage,
            modelContext: modelContext,
            guidanceService: guidanceService
        )
    }
    
    convenience init(
        record: MealHistoryRecord,
        modelContext: ModelContext? = nil,
        guidanceService: MealGuidanceService? = nil
    ) {
        let evaluation = MealEvaluation(
            id: record.id,
            analyzedAt: record.analyzedAt,
            mealName: record.mealName,
            components: record.components,
            categoryEvaluations: record.categoryEvaluations,
            overallStatus: record.overallStatus,
            summary: record.summary
        )
        
        let mealImage = record.imageFileName.flatMap {
            ImageStorageService().load(named: $0)
        }
        
        self.init(
            evaluation: evaluation,
            mealImage: mealImage,
            modelContext: modelContext,
            guidanceService: guidanceService
        )
        
        if record.hasAIGuidance {
            feedback = FeedbackText(
                headline: record.feedbackHeadline ?? record.overallStatus.displayName,
                body: record.feedbackBody ?? record.summary
            )
            
            recommendation = record.recommendation
            guidanceSource = .translated
        } else {
            feedback = fallback.feedback
            recommendation = record.recommendation ?? fallback.recommendation
        }
        
        isGeneratingGuidance = false
        hasLoaded = true
    }

    /// Stage 1: get English guidance from the on-device model, then trigger
    /// translation. Keeps the deterministic fallback if the model is absent.
    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        // Already generated once for this meal? Reuse the cached AI guidance so
        // the text is identical on every reopen (no fresh model call).
        if let record = fetchRecord(), record.hasAIGuidance {
            feedback = FeedbackText(
                headline: record.feedbackHeadline ?? evaluation.overallStatus.displayName,
                body: record.feedbackBody ?? ""
            )
            recommendation = record.recommendation
            advanceGuidance(to: .translated)
            isGeneratingGuidance = false
            NSLog("UPDISH_CACHE: reused stored AI guidance for \"\(evaluation.mealName)\"")
            return
        }

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
            let body = Self.informal(try await session.translate(english.feedbackBody).targetText)
            let summary = english.recommendationSummary.isEmpty
                ? ""
                : Self.informal(try await session.translate(english.recommendationSummary).targetText)

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
            persistGuidance()
            NSLog("UPDISH_STAGE2_TRANSLATE: success → \"\(body)\"")
        } catch {
            NSLog("UPDISH_STAGE2_TRANSLATE: FAILED (\(error)) — showing deterministic fallback")
            applyFallback()
        }
    }
    #endif

    // MARK: - Tone

    /// Apple's translator renders "you" as the formal "Anda", but the rest of
    /// the app speaks casually ("piringmu", "makananmu"). Swap the pronoun and
    /// repair sentence capitalisation so the tone stays consistent.
    private static func informal(_ text: String) -> String {
        let swapped = text.replacingOccurrences(
            of: "\\bAnda\\b",
            with: "kamu",
            options: [.regularExpression]
        )
        return capitalizingSentences(swapped)
    }

    private static func capitalizingSentences(_ text: String) -> String {
        var result = ""
        var startOfSentence = true

        for character in text {
            if startOfSentence, character.isLetter {
                result.append(contentsOf: character.uppercased())
                startOfSentence = false
            } else {
                result.append(character)
                if character == "." || character == "!" || character == "?" {
                    startOfSentence = true
                }
            }
        }
        return result
    }

    // MARK: - Caching

    /// Looks up the stored history record for this meal, if persistence is on.
    private func fetchRecord() -> MealHistoryRecord? {
        guard let modelContext else { return nil }
        let id = evaluation.id
        var descriptor = FetchDescriptor<MealHistoryRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    /// Saves the freshly generated AI feedback + recommendation onto the record
    /// so the next open reuses them. Only called after a successful translation,
    /// never for the deterministic fallback (which is already stable).
    private func persistGuidance() {
        guard let modelContext, let record = fetchRecord() else { return }
        record.feedbackHeadline = feedback?.headline
        record.feedbackBody = feedback?.body
        record.recommendation = recommendation
        try? modelContext.save()
    }
}
