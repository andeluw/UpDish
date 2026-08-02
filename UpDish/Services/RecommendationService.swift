//
//  RecommendationService.swift
//  UpDish
//
//  Builds a MealRecommendation from an evaluation. Options are picked from a
//  curated database (>= 5 per category) so portions are always accurate and
//  number-free. Returns nil when the plate is already complete — this is what
//  makes recommendations appear ONLY for Sedikit / Tidak Ada.
//
//  Portions come from `PortionGuide`, the single source of truth shared with
//  the Foundation Model path, so both routes show the same household units.
//

import Foundation

struct RecommendationService {

    /// Curated foods per category (>= 5 each). Portions are attached from
    /// `PortionGuide` at build time so this list only has to name the foods.
    private static let foodsByCategory: [FoodCategory: [String]] = [
        .stapleFood: ["Nasi Merah", "Kentang Rebus", "Jagung Rebus", "Ubi Rebus", "Roti Gandum"],
        .protein: ["Telur Rebus", "Tahu", "Tempe", "Ikan", "Ayam"],
        .vegetable: ["Tumis Bayam", "Capcay", "Urap / Lalapan", "Sup Sayur", "Brokoli Rebus"],
        .fruit: ["Pisang", "Pepaya", "Semangka", "Apel", "Jeruk"]
    ]

    private let optionsByCategory: [FoodCategory: [RecommendationOption]] =
        foodsByCategory.reduce(into: [:]) { result, entry in
            result[entry.key] = entry.value.map { name in
                RecommendationOption(
                    name: name,
                    portionDescription: PortionGuide.portion(for: name, category: entry.key)
                )
            }
        }

    /// Returns nil when nothing needs improving (all groups sufficient).
    func recommendation(for evaluation: MealEvaluation) -> MealRecommendation? {
        let weak = evaluation.categoriesNeedingImprovement
        guard !weak.isEmpty else { return nil }

        let groups = weak.map { entry in
            RecommendationGroup(
                category: entry.category,
                options: optionsByCategory[entry.category] ?? []
            )
        }

        return MealRecommendation(
            title: "Rekomendasi Perbaikan",
            message: describe(weakCategories: weak.map(\.category)),
            groups: groups
        )
    }

    // MARK: - Narrative

    /// Deterministic, category-accurate summary line — names only the groups
    /// that actually need completing. Exposed so the Foundation Model path
    /// (which supplies its own food choices) reuses the exact same message and
    /// can never mention a group that's already sufficient.
    func summary(for evaluation: MealEvaluation) -> String {
        describe(weakCategories: evaluation.categoriesNeedingImprovement.map(\.category))
    }

    private func describe(weakCategories: [FoodCategory]) -> String {
        let hasSayur = weakCategories.contains(.vegetable)
        let hasBuah = weakCategories.contains(.fruit)

        switch (hasSayur, hasBuah) {
        case (true, true):
            return "Tambahkan sayur untuk serat, vitamin, dan mineral. Jangan lupa buah untuk vitamin dan antioksidan."
        case (false, true):
            return "Lengkapi dengan buah-buahan agar kebutuhan vitamin dan seratmu lebih seimbang."
        case (true, false):
            return "Tambahkan sayur agar piringmu lebih lengkap dengan serat dan vitamin."
        default:
            return "Lengkapi komponen yang masih kurang agar komposisi piringmu lebih seimbang."
        }
    }
}
