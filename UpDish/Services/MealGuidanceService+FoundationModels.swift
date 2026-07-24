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
    @Guide(description: "Exactly two complete sentences of natural English prose. NEVER output a bare list of food names — every part must be a full sentence with a verb. Sentence 1 says what the plate contains, naming each actual food exactly as given. Sentence 2 covers what still needs completing, or confirms the plate already meets the standard when nothing does. Never quote the prompt's internal labels back at the user. No numbers.")
    let feedbackBody: String

    @Guide(description: "One encouraging English sentence about the benefit of completing the missing groups. No numbers.")
    let recommendationSummary: String

    // Bounded: an unbounded array let the model generate until it blew the
    // 4096-token context window, which failed the whole request and silently
    // dropped the user to the template fallback.
    @Guide(.maximumCount(6))
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
                generating: GeneratedGuidance.self,
                // Low temperature: at the default the model intermittently
                // produced a bare list instead of sentences, repeated a clause
                // three times, or echoed the prompt's own wording back at the
                // user. 0.3 held the format steady across repeated runs.
                options: GenerationOptions(temperature: 0.3)
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

        How to write the feedback:
        - ALWAYS name the user's actual foods, for every verdict without \
        exception. Even when the plate is complete and you are only \
        celebrating, say which foods it is made of. Never describe the plate \
        only in the abstract, like "a staple food and a protein".
        - Copy every food name EXACTLY as it was given to you, character for \
        character. These are dish names, NOT words to translate. If the plate \
        says "Telur Dadar", write "Telur Dadar" — never "fried chicken" or \
        "omelette". Naming a food the user does not have is the worst mistake \
        you can make.
        - Clearly distinguish a group that is PRESENT BUT TOO LITTLE (the food \
        is on the plate but the portion is small — say it is there, then say \
        more can be added) from a group that is COMPLETELY MISSING (not on the \
        plate at all — say it is not there yet). Never word these two the same \
        way.
        - Never call the plate balanced, complete, healthy, or "a good start" \
        while any group is too small or missing.
        - Never praise a group whose portion is too small.
        - When every group is already sufficient, simply celebrate it. Do NOT \
        suggest adding anything, and do NOT mention improving a group that is \
        already enough.
        - Never mention calories, grams, or any nutrient amount.
        - Write in English (it is translated afterwards). Keep the tone warm and \
        simple, but always state plainly which groups still need adding.
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

        guard !tooLittle.isEmpty || !missing.isEmpty else {
            return balancedPrompt(for: evaluation)
        }
        return completionPrompt(for: evaluation, tooLittle: tooLittle, missing: missing)
    }

    /// Nothing is short, so the group labels are omitted entirely — with them
    /// present the model read them back as "Nasi Putih (staple food), ...".
    private func balancedPrompt(for evaluation: MealEvaluation) -> String {
        let foods = evaluation.components
            .map { "- \($0.name)" }
            .joined(separator: "\n")

        return """
        Here is one Indonesian home-cooked plate. Every group on it is \
        sufficient, and the user is being shown the verdict "Seimbang" \
        (balanced).

        Foods on the plate:
        \(foods.isEmpty ? "- (none listed)" : foods)

        Write:
        1. feedbackBody — two sentences. The first names these foods, spelled \
        exactly as above. The second says they already meet the Isi Piringku \
        standard, and encourages keeping it up.
        2. recommendationSummary — one warm sentence about keeping this habit.
        3. suggestions — leave empty.
        """
    }

    /// At least one group is short. The group label stays on each food here
    /// because the model needs it to connect "vegetables" in the shortfall
    /// lines to the actual dish on the plate.
    private func completionPrompt(
        for evaluation: MealEvaluation,
        tooLittle: [String],
        missing: [String]
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

        Already on the plate, but the portion is too small: \
        \(tooLittle.isEmpty ? "none" : tooLittle.joined(separator: ", "))
        Not on the plate at all: \
        \(missing.isEmpty ? "none" : missing.joined(separator: ", "))

        Write:
        1. feedbackBody — two sentences. The first names the foods above, \
        spelled exactly as above. The second covers every group listed on the \
        two lines above: for a group whose portion is too small, say that food \
        is already on the plate and more of it can be added; for a group that \
        is not on the plate, say it is not there yet and can be added. \
        Describe the groups in ordinary words.
        2. recommendationSummary — encourage completing those groups.
        3. suggestions — 2-3 choices with portions for each group listed on \
        those two lines.
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
