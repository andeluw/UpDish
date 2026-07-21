//
//  MealHistoryRecord.swift
//  UpDish
//
//  Created by Andrew Wallace on 13/07/26.
//

import Foundation
import SwiftData

@Model
final class MealHistoryRecord {
    @Attribute(.unique)
    var id: UUID
    
    var analyzedAt: Date
    var mealName: String
    var overallStatus: MealBalanceStatus
    var summary: String
    var imageFileName: String?

    var components: [MealComponent]

    var categoryEvaluations: [CategoryEvaluation]
    var recommendation: MealRecommendation?

    /// The AI-generated feedback (already translated to Indonesian), cached so
    /// reopening the same meal shows the exact same text instead of the model
    /// generating a fresh, different response each time. Nil until the
    /// Foundation Model + translation pipeline has succeeded once.
    var feedbackHeadline: String?
    var feedbackBody: String?

    /// True once the AI feedback has been generated and stored.
    var hasAIGuidance: Bool {
        !(feedbackBody?.isEmpty ?? true)
    }

    init(
        id: UUID = UUID(),
        analyzedAt: Date = Date(),
        mealName: String,
        overallStatus: MealBalanceStatus,
        summary: String,
        imageFileName: String? = nil,
        components: [MealComponent],
        categoryEvaluations: [CategoryEvaluation],
        recommendation: MealRecommendation? = nil,
        feedbackHeadline: String? = nil,
        feedbackBody: String? = nil
    ) {
        self.id = id
        self.analyzedAt = analyzedAt
        self.mealName = mealName
        self.overallStatus = overallStatus
        self.summary = summary
        self.imageFileName = imageFileName
        self.components = components
        self.categoryEvaluations = categoryEvaluations
        self.recommendation = recommendation
        self.feedbackHeadline = feedbackHeadline
        self.feedbackBody = feedbackBody
    }
}

extension MealHistoryRecord {
    convenience init(
        result: MealResult,
        imageFileName: String? = nil
    ) {
        self.init(
            id: result.evaluation.id,
            analyzedAt: result.evaluation.analyzedAt,
            mealName: result.evaluation.mealName,
            overallStatus: result.evaluation.overallStatus,
            summary: result.evaluation.summary,
            imageFileName: imageFileName,
            components: result.evaluation.components,
            categoryEvaluations: result.evaluation.categoryEvaluations,
            recommendation: result.recommendation
        )
    }
    
    func toMealResult() -> MealResult {
        MealResult(
            evaluation: MealEvaluation(
                id: id,
                analyzedAt: analyzedAt,
                mealName: mealName,
                components: components,
                categoryEvaluations: categoryEvaluations,
                overallStatus: overallStatus,
                summary: summary
            ),
            recommendation: recommendation
        )
    }
}
