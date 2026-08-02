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
    // The feedback paragraph and the recommendation summary are built
    // deterministically from the evaluation (naming every food + the checklist
    // statuses), so the model's ONLY job is the recommendation food choices —
    // the one part that benefits from its variety. Everything it used to write
    // in prose (which foods are on the plate, which groups are short) is now
    // generated from the checklist data, so it can never drop a food or
    // contradict the verdict.
    //
    // Bounded: an unbounded array let the model generate until it blew the
    // 4096-token context window, which failed the whole request and silently
    // dropped the user to the template fallback.
    @Guide(.maximumCount(6))
    @Guide(description: "For EACH group that still needs completing, give 2-3 food choices. Leave empty if nothing needs completing.")
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
                generating: GeneratedGuidance.self,
                // Low temperature: at the default the model intermittently
                // produced a bare list instead of sentences, repeated a clause
                // three times, or echoed the prompt's own wording back at the
                // user. 0.3 held the format steady across repeated runs.
                options: GenerationOptions(temperature: 0.3)
            )
            let content = response.content

            return EnglishGuidance(
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

    /// Deliberately compact. This text plus the @Guide descriptions is fixed
    /// overhead on every request, and the model only has a 4096-token context —
    /// the original 844-token version left so little headroom that generation
    /// intermittently failed outright. The portion-unit rules that used to be
    /// duplicated here now live only on `foodWithPortion`, where they apply.
    ///
    /// Constraints belong here rather than in the prompt: the model echoes the
    /// prompt back at the user far more readily than it echoes its instructions.
    private static var instructions: String {
        """
        You are a nutrition assistant for home cooks in Indonesia, following the \
        Ministry of Health's "Isi Piringku" guideline for one plate per meal: \
        1/3 staple food, 1/3 vegetables, 1/6 protein side dish, 1/6 fruit. Half \
        the plate is vegetables and fruit.

        Your only job is to suggest foods for the groups that still need \
        completing. Rules:
        - Suggest common, everyday Indonesian foods that fit each group, and \
        match every suggestion to the correct group.
        - Only suggest for the groups the prompt says are too small or missing. \
        Never suggest for a group the prompt says is already fine.
        - Never mention calories, grams, or any nutrient amount.
        - Write in English (it is translated afterwards).
        """
    }

    // MARK: Prompt (English only — no Indonesian, or the input guardrail rejects it)

    /// Two shapes rather than one, because the two situations genuinely differ.
    /// A single template whose second sentence flipped meaning depending on the
    /// verdict made the model invent problems on a balanced plate ("the portion
    /// of Tumis Kangkung is too small" when nothing was), so the balanced case
    /// gets its own prompt that never mentions shortfalls at all.
    ///
    /// Both are phrased positively and avoid shouted rules: negative, all-caps
    /// instructions in the prompt body were being reproduced verbatim in the
    /// user-facing text.
    private func prompt(for evaluation: MealEvaluation) -> String {
        let tooLittle = evaluation.categoryEvaluations
            .filter { $0.status == .insufficient }
            .map(\.category.englishName)
        let missing = evaluation.categoryEvaluations
            .filter { $0.status == .missing }
            .map(\.category.englishName)
        let sufficient = evaluation.categoryEvaluations
            .filter { $0.status == .sufficient }
            .map(\.category.englishName)

        guard !tooLittle.isEmpty || !missing.isEmpty else {
            return balancedPrompt(for: evaluation)
        }
        return completionPrompt(for: evaluation, tooLittle: tooLittle, missing: missing, sufficient: sufficient)
    }

    /// Every group is already sufficient, so there is nothing to suggest.
    private func balancedPrompt(for evaluation: MealEvaluation) -> String {
        """
        Here is one Indonesian home-cooked plate. Every group on it is already \
        sufficient, so nothing needs to be added.

        Return an empty suggestions list.
        """
    }

    /// At least one group is short. The group label stays on each food here
    /// because the model needs it to connect "vegetables" in the shortfall
    /// lines to the actual dish on the plate.
    private func completionPrompt(
        for evaluation: MealEvaluation,
        tooLittle: [String],
        missing: [String],
        sufficient: [String]
    ) -> String {
        // `category` is optional: detection may not have classified an item
        // yet, in which case we still name the food but omit the group label.
        let foods = evaluation.components
            .map { component -> String in
                guard let category = component.category else { return "- \(component.name)" }
                return "- \(component.name) (\(category.englishName))"
            }
            .joined(separator: "\n")

        return """
        Here is one Indonesian home-cooked plate. The user is being shown the \
        verdict "\(evaluation.overallStatus.displayName)", meaning \
        \(Self.verdictGloss(for: evaluation.overallStatus))

        Foods on the plate:
        \(foods.isEmpty ? "- (none listed)" : foods)

        Groups that are too small and need more: \
        \(tooLittle.isEmpty ? "none" : tooLittle.joined(separator: ", "))
        Groups not on the plate at all: \
        \(missing.isEmpty ? "none" : missing.joined(separator: ", "))
        Groups already fine — do NOT suggest anything for these: \
        \(sufficient.isEmpty ? "none" : sufficient.joined(separator: ", "))

        Suggest 2-3 food choices with portions for EACH group on the "too \
        small" and "not on the plate" lines, and nothing for the groups that \
        are already fine. The foods list is context so your suggestions are \
        different from what is already there.
        """
    }

    /// Plain-language gloss of the verdict the user is already looking at, so
    /// the model's wording can't contradict the card.
    private static func verdictGloss(for status: MealBalanceStatus) -> String {
        switch status {
        case .balanced:
            return "every group is already sufficient."
        case .mostlyBalanced:
            return "one group still needs completing."
        case .needsImprovement:
            return "more than one group still needs completing."
        }
    }
}

@available(iOS 26.0, *)
extension GeneratedCategory {
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
