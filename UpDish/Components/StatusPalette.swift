//
//  StatusPalette.swift
//  UpDish
//
//  UI-layer colour + icon mapping for the shared evaluation statuses. Keeping
//  this in the Components layer lets the Models stay pure data.
//

import SwiftUI

extension MealBalanceStatus {
    var accentColor: Color {
        switch self {
        case .balanced: Color(red: 0.20, green: 0.62, blue: 0.31)
        case .mostlyBalanced: Color(red: 0.62, green: 0.55, blue: 0.02)
        case .needsImprovement: Color(red: 0.80, green: 0.24, blue: 0.29)
        }
    }

    var cardBackground: Color {
        switch self {
        case .balanced: Color(red: 0.87, green: 0.94, blue: 0.86)
        case .mostlyBalanced: Color(red: 0.95, green: 0.96, blue: 0.82)
        case .needsImprovement: Color(red: 0.98, green: 0.89, blue: 0.90)
        }
    }
}

extension CategoryStatus {
    /// Does the category count as "on the plate" for the plate visual?
    var isPresent: Bool {
        self != .missing
    }

    /// SF Symbol shown next to a category in the checklist.
    var iconName: String {
        switch self {
        case .sufficient: "checkmark.circle.fill"
        case .insufficient: "exclamationmark.circle.fill"
        case .missing: "xmark.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .sufficient: Color(red: 0.20, green: 0.62, blue: 0.31)
        case .insufficient: Color(red: 0.90, green: 0.62, blue: 0.10)
        case .missing: Color(red: 0.85, green: 0.23, blue: 0.27)
        }
    }

    /// Fill colour for this category's wedge on the plate.
    var plateFill: Color {
        isPresent
            ? Color(red: 0.85, green: 0.93, blue: 0.82)  // soft green
            : Color(red: 0.98, green: 0.85, blue: 0.86)  // soft pink
    }
}
