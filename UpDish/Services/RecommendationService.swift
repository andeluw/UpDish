//
//  RecommendationService.swift
//  UpDish
//
//  Builds a MealRecommendation from an evaluation. Options are picked from a
//  curated database (>= 5 per category) so portions are always accurate and
//  number-free. Returns nil when the plate is already complete — this is what
//  makes recommendations appear ONLY for Sedikit / Tidak Ada.
//

import Foundation

struct RecommendationService {

    /// Curated options per category. Populate with at least 5 each.
    private let optionsByCategory: [FoodCategory: [RecommendationOption]] = [
        .stapleFood: [
            RecommendationOption(name: "Nasi Merah", portionDescription: "1 centong"),
            RecommendationOption(name: "Kentang Rebus", portionDescription: "1 buah sedang"),
            RecommendationOption(name: "Jagung Rebus", portionDescription: "1 buah"),
            RecommendationOption(name: "Ubi Rebus", portionDescription: "1 potong sedang"),
            RecommendationOption(name: "Roti Gandum", portionDescription: "2 lembar")
        ],
        .protein: [
            RecommendationOption(name: "Telur Rebus", portionDescription: "1 butir"),
            RecommendationOption(name: "Tahu", portionDescription: "2 potong"),
            RecommendationOption(name: "Tempe", portionDescription: "2 potong"),
            RecommendationOption(name: "Ikan", portionDescription: "1 potong sedang"),
            RecommendationOption(name: "Ayam", portionDescription: "1 potong sedang")
        ],
        .vegetable: [
            RecommendationOption(name: "Tumis Bayam", portionDescription: "1 porsi sedang"),
            RecommendationOption(name: "Capcay / Sayur Bening", portionDescription: "1 porsi sedang"),
            RecommendationOption(name: "Urap / Lalapan", portionDescription: "1 porsi sedang"),
            RecommendationOption(name: "Sup Sayur", portionDescription: "1 mangkuk kecil"),
            RecommendationOption(name: "Brokoli Rebus", portionDescription: "1 porsi sedang")
        ],
        .fruit: [
            RecommendationOption(name: "Pisang", portionDescription: "1 buah sedang"),
            RecommendationOption(name: "Pepaya", portionDescription: "1 potong sedang"),
            RecommendationOption(name: "Semangka", portionDescription: "2 potong kecil"),
            RecommendationOption(name: "Apel", portionDescription: "1/2 buah sedang"),
            RecommendationOption(name: "Jeruk", portionDescription: "1 buah sedang")
        ]
    ]

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
