//
//  MealRecommendation.swift
//  UpDish
//
//  Created by Andrew Wallace on 13/07/26.
//

import Foundation

struct RecommendationOption: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let portionDescription: String
    
    init(
        id: UUID = UUID(),
        name: String,
        portionDescription: String
    ) {
        self.id = id
        self.name = name
        self.portionDescription = portionDescription
    }
}

struct RecommendationGroup: Identifiable, Codable, Hashable {
    let category: FoodCategory
    let options: [RecommendationOption]
    
    var id: FoodCategory {
        category
    }
}

struct MealRecommendation: Codable, Hashable {
    let title: String
    let message: String
    let groups: [RecommendationGroup]
}
