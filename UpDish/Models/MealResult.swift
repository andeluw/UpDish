//
//  MealResult.swift
//  UpDish
//
//  Created by Andrew Wallace on 13/07/26.
//

import Foundation

struct MealResult: Identifiable, Codable, Hashable {
    let evaluation: MealEvaluation
    let recommendation: MealRecommendation?
    
    var id: UUID {
        evaluation.id
    }
}
