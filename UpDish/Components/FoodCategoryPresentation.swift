//
//  FoodCategoryPresentation.swift
//  UpDish
//
//  UI + plate-layout helpers for the shared FoodCategory model. Kept out of
//  the model file so the team's Models stay pure data.
//

import Foundation

extension FoodCategory {
    /// Label used in the composition checklist beside the plate. Longer than
    /// `displayName`, which stays short so it reads well inside sentences.
    var checklistName: String {
        switch self {
        case .stapleFood: "Makanan Pokok"
        case .protein: "Lauk Pauk"
        case .vegetable: "Sayuran"
        case .fruit: "Buah-buahan"
        }
    }

    /// Short slug used inside plate asset filenames (see IsiPiringkuPlateView).
    var assetSlug: String {
        switch self {
        case .stapleFood: "karbo"
        case .protein: "lauk"
        case .vegetable: "sayur"
        case .fruit: "buah"
        }
    }

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
