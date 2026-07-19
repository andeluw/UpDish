//
//  MealComponent.swift
//  UpDish
//
//  Created by Andrew Wallace on 13/07/26.
//

import Foundation

struct MealComponent: Identifiable, Codable, Hashable {
    let id: UUID
    
    var name: String
    var category: FoodCategory?
    var portionPercentage: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        category: FoodCategory? = nil,
        portionPercentage: Int
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.portionPercentage = portionPercentage
    }
}
