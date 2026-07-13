//
//  MealEvaluation.swift
//  UpDish
//
//  Created by Andrew Wallace on 13/07/26.
//

import Foundation

enum CategoryStatus: String, Codable, Hashable {
    case sufficient
    case insufficient
    case missing
    
    var displayName: String {
        switch self {
        case .sufficient:
            return "Cukup"
        case .insufficient:
            return "Sedikit"
        case .missing:
            return "Tidak Ada"
        }
    }
    
    var needsImprovement: Bool {
        self != .sufficient
    }
}

struct CategoryEvaluation: Identifiable, Codable, Hashable {
    let category: FoodCategory
    let portionPercentage: Int
    let status: CategoryStatus
    let targetPercentage: Double
    
    var id: FoodCategory {
        category
    }
    
    var portionPercentageValue: Double {
        Double(portionPercentage)
    }
    
    var differenceFromTarget: Double {
        portionPercentageValue - targetPercentage
    }
}

enum MealBalanceStatus: String, Codable, Hashable {
    case balanced
    case mostlyBalanced
    case needsImprovement
    
    var displayName: String {
        switch self {
        case .balanced:
            return "Seimbang"
        case .mostlyBalanced:
            return "Cukup Baik"
        case .needsImprovement:
            return "Perlu Diperbaiki"
        }
    }
}

struct MealEvaluation: Identifiable, Codable, Hashable {
    let id: UUID
    let analyzedAt: Date
    let mealName: String
    let components: [MealComponent]
    let categoryEvaluations: [CategoryEvaluation]
    let overallStatus: MealBalanceStatus
    let summary: String
    
    init(
        id: UUID = UUID(),
        analyzedAt: Date = Date(),
        mealName: String,
        components: [MealComponent],
        categoryEvaluations: [CategoryEvaluation],
        overallStatus: MealBalanceStatus,
        summary: String
    ) {
        self.id = id
        self.analyzedAt = analyzedAt
        self.mealName = mealName
        self.components = components
        self.categoryEvaluations = categoryEvaluations
        self.overallStatus = overallStatus
        self.summary = summary
    }
    
    var categoriesNeedingImprovement: [CategoryEvaluation] {
        categoryEvaluations.filter {
            $0.status.needsImprovement
        }
    }
    
    var totalPercentage: Int {
        components.reduce(0) {
            $0 + $1.portionPercentage
        }
    }
}
