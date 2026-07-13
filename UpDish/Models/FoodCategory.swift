//
//  FoodCategory.swift
//  UpDish
//
//  Created by Andrew Wallace on 13/07/26.
//

import Foundation

enum FoodCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case stapleFood
    case protein
    case vegetable
    case fruit
    
    var id: String {
        rawValue
    }
    
    var displayName: String {
        switch self {
        case .stapleFood:
            return "Makanan Pokok"
        case .protein:
            return "Lauk-Pauk"
        case .vegetable:
            return "Sayur"
        case .fruit:
            return "Buah"
        }
    }
    
    // Recommended portion of the entire plate.
    var targetPercentage: Double {
        switch self {
        case .stapleFood:
            return 100.0 / 3.0
        case .protein:
            return 100.0 / 6.0
        case .vegetable:
            return 100.0 / 3.0
        case .fruit:
            return 100.0 / 6.0
        }
    }
}
