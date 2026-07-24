//
//  FeedbackService.swift
//  UpDish
//
//  Deterministic, number-free feedback text. This is the FALLBACK used when
//  the on-device model is unavailable — the primary feedback comes from
//  MealGuidanceService via Foundation Models + translation.
//

import Foundation

/// The text rendered in the feedback card.
struct FeedbackText {
    let headline: String
    let body: String
}

struct FeedbackService {

    func templateFeedback(for evaluation: MealEvaluation) -> FeedbackText {
        let headline = evaluation.overallStatus.displayName
        let opening = plateSummary(for: evaluation)

        if evaluation.overallStatus == .balanced {
            let praise = opening.isEmpty
                ? "Komposisi makananmu sudah seimbang. Pertahankan, ya!"
                : "Komposisinya sudah seimbang. Pertahankan, ya!"
            return FeedbackText(headline: headline, body: opening + praise)
        }

        return FeedbackText(
            headline: headline,
            body: opening + composeBody(for: evaluation)
        )
    }

    /// Names the foods the user actually submitted, so every verdict — balanced
    /// included — describes THEIR plate rather than talking about groups in the
    /// abstract. The model is instructed to do the same, so the two paths read
    /// alike instead of feeling like two different apps.
    ///
    /// Empty when nothing was listed, which lets the caller fall back to
    /// wording that reads correctly without it.
    private func plateSummary(for evaluation: MealEvaluation) -> String {
        let foods = evaluation.components
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !foods.isEmpty else { return "" }
        return "Piringmu berisi \(list(foods)). "
    }

    // MARK: - "Ada tapi kurang" vs "belum ada"

    /// Builds a sentence that separates groups that are PRESENT-BUT-TOO-LITTLE
    /// (Sedikit) from groups that are COMPLETELY MISSING (Tidak Ada), so the
    /// user knows whether to add more of something or add it at all.
    private func composeBody(for evaluation: MealEvaluation) -> String {
        let tooLittle = names(in: evaluation, matching: .insufficient)
        let missing = names(in: evaluation, matching: .missing)

        var clauses: [String] = []
        if !tooLittle.isEmpty {
            clauses.append("\(list(tooLittle)) sudah ada tapi porsinya masih kurang")
        }
        if !missing.isEmpty {
            clauses.append("\(list(missing)) belum ada di piringmu")
        }

        guard !clauses.isEmpty else {
            return "Komposisi makanan sudah cukup seimbang, tinggal dirapikan sedikit."
        }

        let joined = clauses.joined(separator: ", sedangkan ")
        let sentence = joined.prefix(1).uppercased() + joined.dropFirst()
        return "\(sentence). Yuk, lengkapi agar piringmu lebih seimbang."
    }

    private func names(
        in evaluation: MealEvaluation,
        matching status: CategoryStatus
    ) -> [String] {
        evaluation.categoryEvaluations
            .filter { $0.status == status }
            .map { $0.category.displayName.lowercased() }
    }

    /// "sayur" · "sayur dan buah" · "sayur, buah, dan lauk-pauk"
    private func list(_ names: [String]) -> String {
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2: return "\(names[0]) dan \(names[1])"
        default:
            let head = names.dropLast().joined(separator: ", ")
            return "\(head), dan \(names.last ?? "")"
        }
    }
}
