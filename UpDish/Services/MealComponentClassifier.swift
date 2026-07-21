//
//  MealComponentClassifier.swift
//  UpDish
//
//  Detection returns food names and portions but no Isi Piringku group, and
//  `MealComponent.category` is optional — so without this step every component
//  would match no category and the whole plate would evaluate as empty.
//
//  Two passes, cheapest first:
//    1. A local keyword table. Instant, offline, works on the Simulator, and
//       covers the common Indonesian foods this app sees.
//    2. The on-device model, for anything the table doesn't recognise.
//
//  Anything still unresolved keeps a nil category and simply won't count — the
//  user can still correct it on the component screen.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct MealComponentClassifier {

    /// Returns the components with `category` filled in wherever it was nil.
    /// Components that already have a category are left untouched.
    func classify(_ components: [MealComponent]) async -> [MealComponent] {
        var result = components.map { component -> MealComponent in
            guard component.category == nil else { return component }
            var resolved = component
            resolved.category = Self.knownCategory(for: component.name)
            return resolved
        }

        let unresolved = result.indices.filter { result[$0].category == nil }
        guard !unresolved.isEmpty else { return result }

        NSLog("UPDISH_CLASSIFY: asking the model about \(unresolved.count) unknown food(s)")
        guard let aiResolved = await aiCategories(for: unresolved.map { result[$0].name }) else {
            return result
        }

        for index in unresolved {
            let key = Self.normalized(result[index].name)
            if let category = aiResolved[key] {
                result[index].category = category
            }
        }
        return result
    }

    // MARK: - Local keyword table

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Matched in order, so more specific phrases win — "kacang panjang" is a
    /// vegetable while plain "kacang" is a protein side. Vegetables and fruit
    /// come first because several of their names contain staple/protein
    /// substrings (e.g. "kubis" contains "ubi").
    private static let keywords: [(match: String, category: FoodCategory)] = [
        // Sayuran
        ("kacang panjang", .vegetable),
        ("sayur", .vegetable), ("bayam", .vegetable), ("kangkung", .vegetable),
        ("sawi", .vegetable), ("brokoli", .vegetable), ("wortel", .vegetable),
        ("buncis", .vegetable), ("kubis", .vegetable), ("kol", .vegetable),
        ("terong", .vegetable), ("timun", .vegetable), ("tomat", .vegetable),
        ("capcay", .vegetable), ("urap", .vegetable), ("lalapan", .vegetable),
        ("tauge", .vegetable), ("toge", .vegetable), ("jamur", .vegetable),
        ("labu", .vegetable), ("pare", .vegetable), ("selada", .vegetable),
        ("oyong", .vegetable), ("daun", .vegetable),

        // Buah-buahan
        ("buah", .fruit), ("pisang", .fruit), ("pepaya", .fruit),
        ("semangka", .fruit), ("apel", .fruit), ("jeruk", .fruit),
        ("mangga", .fruit), ("nanas", .fruit), ("melon", .fruit),
        ("anggur", .fruit), ("alpukat", .fruit), ("salak", .fruit),
        ("rambutan", .fruit), ("jambu", .fruit), ("stroberi", .fruit),
        ("kiwi", .fruit), ("belimbing", .fruit), ("duku", .fruit),

        // Makanan pokok
        ("nasi", .stapleFood), ("kentang", .stapleFood), ("jagung", .stapleFood),
        ("singkong", .stapleFood), ("ubi", .stapleFood), ("roti", .stapleFood),
        ("bihun", .stapleFood), ("mie", .stapleFood), ("pasta", .stapleFood),
        ("lontong", .stapleFood), ("ketupat", .stapleFood), ("sagu", .stapleFood),
        ("talas", .stapleFood), ("bubur", .stapleFood), ("oat", .stapleFood),

        // Lauk-pauk
        ("ayam", .protein), ("daging", .protein), ("sapi", .protein),
        ("kambing", .protein), ("ikan", .protein), ("telur", .protein),
        ("tahu", .protein), ("tempe", .protein), ("udang", .protein),
        ("cumi", .protein), ("bakso", .protein), ("sosis", .protein),
        ("teri", .protein), ("lele", .protein), ("tongkol", .protein),
        ("bandeng", .protein), ("rendang", .protein), ("empal", .protein),
        ("abon", .protein), ("hati", .protein), ("kacang", .protein)
    ]

    static func knownCategory(for name: String) -> FoodCategory? {
        let lowered = normalized(name)
        return keywords.first { lowered.contains($0.match) }?.category
    }
}

// MARK: - On-device model fallback

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GeneratedComponentCategory {
    @Guide(description: "The food name, copied back exactly as it was given")
    let name: String

    @Guide(description: "Which Isi Piringku group this food belongs to")
    let category: GeneratedCategory
}

@available(iOS 26.0, *)
@Generable
struct GeneratedComponentCategories {
    @Guide(description: "Exactly one entry for every food name that was given")
    let items: [GeneratedComponentCategory]
}
#endif

private extension MealComponentClassifier {

    /// Maps lowercased food name -> category. Nil when the model is unavailable
    /// or the call fails; the caller then leaves those components unclassified.
    func aiCategories(for names: [String]) async -> [String: FoodCategory]? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard case .available = SystemLanguageModel.default.availability else {
                NSLog("UPDISH_CLASSIFY: model unavailable — leaving foods unclassified")
                return nil
            }

            do {
                let session = LanguageModelSession(instructions: Self.instructions)
                let prompt = """
                Sort each of these Indonesian foods into its Isi Piringku group:
                \(names.map { "- \($0)" }.joined(separator: "\n"))
                """
                let response = try await session.respond(
                    to: prompt,
                    generating: GeneratedComponentCategories.self
                )

                var mapping: [String: FoodCategory] = [:]
                for item in response.content.items {
                    mapping[Self.normalized(item.name)] = item.category.appCategory
                }
                NSLog("UPDISH_CLASSIFY: model classified \(mapping.count) food(s)")
                return mapping
            } catch {
                NSLog("UPDISH_CLASSIFY: failed (\(error))")
                return nil
            }
        }
        #endif
        return nil
    }

    static var instructions: String {
        """
        You sort Indonesian foods into the four "Isi Piringku" groups:
        - staple food / carbohydrate (makanan pokok)
        - protein side dish (lauk-pauk)
        - vegetables (sayuran)
        - fruit (buah-buahan)

        Give exactly one entry per food you are given, and copy each food name \
        back exactly as it was written. Choose the single group that best \
        describes the food's main ingredient.
        """
    }
}
