//
//  MealGuidanceService+FoundationModels.swift
//  UpDish
//
//  Stage 1 of guidance: the on-device Foundation Model reasons about the dish
//  and writes feedback + recommendations in ENGLISH (the model does not support
//  Indonesian). Stage 2 (translation to Indonesian) happens in the ViewModel.
//
//  Compiled out when the framework is absent; returns nil on any failure so the
//  caller keeps its deterministic fallback. Requires Xcode 26+ / iOS 26+.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Structured model output (English)

@available(iOS 26.0, *)
@Generable
enum GeneratedCategory {
    case makananPokok
    case laukPauk
    case sayuran
    case buah
}

@available(iOS 26.0, *)
@Generable
struct GeneratedSuggestion {
    @Guide(description: "Which Isi Piringku group this suggestion belongs to")
    let category: GeneratedCategory

    @Guide(description: "A common Indonesian food in English, then ' — ', then a household portion whose unit physically matches the food. Use COUNT/PIECE units for solid or sliced foods (e.g. 'Pineapple slices — 2 slices', 'Fried tempeh — 2 pieces', 'Boiled egg — 1 egg', 'Banana — 1 fruit'); a SPOON/SCOOP or plate fraction for rice and staples (e.g. 'White rice — 1 scoop', 'Boiled potato — half a plate'); a BOWL or PLATE fraction for vegetables (e.g. 'Sautéed spinach — 1 small bowl', 'Blanched water spinach — half a plate'). NEVER use volume units like cups or glasses for solid, sliced, or piece foods. NEVER use hand or palm-based units such as 'handful' or 'a palm'. Never mention calories, grams, or nutrient amounts.")
    let foodWithPortion: String
}

@available(iOS 26.0, *)
@Generable
struct GeneratedGuidance {
    @Guide(description: "One or two friendly sentences in simple English describing the plate's balance. No numbers.")
    let feedbackBody: String

    @Guide(description: "One encouraging English sentence about the benefit of completing the missing groups. No numbers.")
    let recommendationSummary: String

    @Guide(description: "For EACH group that needs completing, give 2-3 food choices. Leave empty if nothing needs completing.")
    let suggestions: [GeneratedSuggestion]
}

// MARK: - Generation

@available(iOS 26.0, *)
extension MealGuidanceService {

    func generateEnglishGuidance(for evaluation: MealEvaluation) async -> EnglishGuidance? {
        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            NSLog("UPDISH_FM_UNAVAILABLE: \(Self.reason(for: availability))")
            return nil
        }

        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(
                to: prompt(for: evaluation),
                generating: GeneratedGuidance.self
            )
            let content = response.content

            let feedbackBody = content.feedbackBody.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !feedbackBody.isEmpty else { return nil }

            return EnglishGuidance(
                feedbackBody: feedbackBody,
                recommendationSummary: content.recommendationSummary.trimmingCharacters(in: .whitespacesAndNewlines),
                suggestions: content.suggestions.map {
                    EnglishSuggestion(
                        category: $0.category.appCategory,
                        text: $0.foodWithPortion.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
            )
        } catch {
            NSLog("UPDISH_FM generation error: \(error)")
            return nil
        }
    }

    /// Human-readable explanation of why the on-device model can't be used, so
    /// the console log points straight at the cause (device, Settings, or model
    /// still downloading) instead of a generic "unavailable".
    private static func reason(for availability: SystemLanguageModel.Availability) -> String {
        switch availability {
        case .available:
            return "available"
        case .unavailable(.deviceNotEligible):
            return "device not eligible — this hardware doesn't support Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence is OFF — enable it in Settings › Apple Intelligence & Siri"
        case .unavailable(.modelNotReady):
            return "model not ready — still downloading, or waiting on network/battery"
        case .unavailable(let other):
            return "unavailable: \(other)"
        }
    }

    // MARK: Instructions

    private static var instructions: String {
        """
        You are a nutrition assistant for home cooks in Indonesia. You help them \
        balance their meals according to the Indonesian Ministry of Health's \
        "Isi Piringku" (My Plate) guideline.

        Isi Piringku for one plate per meal:
        - 1/3 plate staple food / carbohydrate
        - 1/3 plate vegetables
        - 1/6 plate protein side dish
        - 1/6 plate fruit
        Half the plate should be vegetables and fruit.

        How to reason:
        - Look at what is already on the plate, then decide which groups are \
        missing or too small.
        - Choose common, affordable Indonesian foods that genuinely complete THIS \
        dish so it approaches the Isi Piringku standard.
        - Make each suggestion specific and practical, with a household portion.

        Portion units MUST match the food's physical form (this matters a lot):
        - Solid / sliced / piece foods → count them: "2 slices", "2 pieces", \
        "1 fruit", "1 egg". (e.g. fruit, tempeh, tofu, meat, eggs)
        - Rice and starchy staples → a spoon/scoop or plate fraction: "1 scoop", \
        "half a plate".
        - Vegetables → a bowl or plate fraction: "1 small bowl", "half a plate".
        - NEVER use volume units (cup, glass) for solid, sliced, or piece foods. \
        You cannot measure sliced pineapple or fried tempeh in cups.
        - NEVER use hand or palm-based units such as "a handful" or "a palm".

        Strict rules:
        - Write everything in English (it will be translated afterwards).
        - NEVER mention calories, grams, or any nutrient amount.
        - Do not suggest anything for a group that is already sufficient.
        - Keep the tone simple, warm, and encouraging.
        """
    }

    // MARK: Prompt (English only — no Indonesian, or the input guardrail rejects it)

    private func prompt(for evaluation: MealEvaluation) -> String {
        let statuses = evaluation.categoryEvaluations
            .map { "- \($0.category.englishName): \(statusLabel($0.status))" }
            .joined(separator: "\n")

        let needsImprovement = evaluation.categoriesNeedingImprovement
            .map(\.category.englishName)
            .joined(separator: ", ")

        return """
        Here is one Indonesian home-cooked plate, described by its Isi Piringku groups.

        Status of each group:
        \(statuses)

        Groups that need completing: \(needsImprovement.isEmpty ? "none" : needsImprovement)

        Task:
        1. feedbackBody: describe the plate's balance warmly.
        2. recommendationSummary: encourage completing the missing groups.
        3. suggestions: give 2-3 food choices with portions for EACH group that \
        needs completing. Do not suggest for groups that are already present.
        """
    }

    private func statusLabel(_ status: CategoryStatus) -> String {
        switch status {
        case .sufficient: "sufficient"
        case .insufficient: "too little"
        case .missing: "missing"
        }
    }
}

@available(iOS 26.0, *)
private extension GeneratedCategory {
    var appCategory: FoodCategory {
        switch self {
        case .makananPokok: .stapleFood
        case .laukPauk: .protein
        case .sayuran: .vegetable
        case .buah: .fruit
        }
    }
}

/// English category label used only inside the model prompt (the model can't
/// take Indonesian input). Not shown in the UI.
private extension FoodCategory {
    var englishName: String {
        switch self {
        case .stapleFood: "staple food (carbohydrate)"
        case .protein: "protein side dish"
        case .vegetable: "vegetables"
        case .fruit: "fruit"
        }
    }
}
#endif
