//
//  MealDetectionService.swift
//  UpDish
//
//  Created by Andrew Wallace on 19/07/26.
//

import UIKit

protocol MealDetectionService {
    func detect(from image: UIImage) async throws -> MealDraft
}
