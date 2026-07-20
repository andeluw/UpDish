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

        if evaluation.overallStatus == .balanced {
            return FeedbackText(
                headline: headline,
                body: "Komposisi makananmu sudah seimbang. Pertahankan, ya!"
            )
        }

        return FeedbackText(headline: headline, body: composeBody(for: evaluation))
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
