//
//  FoodCategoryPresentation.swift
//  UpDish
//
//  UI + plate-layout helpers for the shared FoodCategory model. Kept out of
//  the model file so the team's Models stay pure data.
//

import Foundation

extension FoodCategory {
    var emoji: String {
        switch self {
        case .stapleFood: "🍚"
        case .protein: "🍗"
        case .vegetable: "🥦"
        case .fruit: "🍎"
        }
    }

    /// Share of the plate (0...1), derived from the model's target percentage.
    var plateProportion: Double {
        targetPercentage / 100.0
    }

    /// Fixed order for the checklist beside the plate.
    static var plateOrder: [FoodCategory] {
        [.stapleFood, .protein, .vegetable, .fruit]
    }

    /// Clockwise draw order for the plate visual, starting from the top.
    /// Fruit & protein are the small top wedges; staple & vegetables the large
    /// bottom ones (matching the Isi Piringku diagram).
    static var plateSequence: [FoodCategory] {
        [.fruit, .vegetable, .stapleFood, .protein]
    }
}
