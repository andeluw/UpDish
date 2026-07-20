//
//  MockMealDetectionService.swift
//  UpDish
//
//  Created by Andrew Wallace on 19/07/26.
//

import UIKit

final class MockMealDetectionService: MealDetectionService {
    func detect(from image: UIImage) async throws -> MealDraft {
        MealDraft(
            mealName: "Nasi Ayam Sayur",
            components: [
                MealComponent(
                    name: "Nasi Putih",
                    portionPercentage: 50
                ),
                MealComponent(
                    name: "Ayam Goreng",
                    portionPercentage: 25
                ),
                MealComponent(
                    name: "Tumis Sayur",
                    portionPercentage: 25
                )
            ]
        )
    }
}
