//
//  StatusPalette.swift
//  UpDish
//
//  UI-layer colour + icon mapping for the shared evaluation statuses. Keeping
//  this in the Components layer lets the Models stay pure data.
//

import SwiftUI

extension MealBalanceStatus {
    /// Icon shown on the feedback card for this verdict.
    var iconName: String {
        switch self {
        case .balanced: "hand.thumbsup"
        case .mostlyBalanced: "exclamationmark.triangle"
        case .needsImprovement: "light.beacon.max"
        }
    }

    /// Title, icon and border colour of the feedback card.
    var accentColor: Color {
        switch self {
        case .balanced: Color(red: 80 / 255, green: 85 / 255, blue: 22 / 255)        // #505516
        case .mostlyBalanced: Color(red: 96 / 255, green: 75 / 255, blue: 1 / 255)   // #604B01
        case .needsImprovement: Color(red: 141 / 255, green: 27 / 255, blue: 7 / 255) // #8D1B07
        }
    }

    var cardBackground: Color {
        switch self {
        case .balanced: Color(red: 245 / 255, green: 248 / 255, blue: 229 / 255)     // #F5F8E5
        case .mostlyBalanced: Color(red: 254 / 255, green: 245 / 255, blue: 219 / 255) // #FEF5DB
        case .needsImprovement: Color(red: 254 / 255, green: 238 / 255, blue: 231 / 255) // #FEEEE7
        }
    }
}

extension CategoryStatus {
    /// Does the category count as "on the plate" for the plate visual?
    var isPresent: Bool {
        self != .missing
    }

    /// Token used inside plate asset filenames (see IsiPiringkuPlateView).
    /// The illustrations only distinguish two states — a full "cukup" wedge, or
    /// a flagged one — so both insufficient and missing collapse to "kurang".
    var assetToken: String {
        switch self {
        case .sufficient: "cukup"
        case .insufficient, .missing: "kurang"
        }
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

    /// Fill colour for this category's wedge on the plate. Green only when the
    /// group is fully sufficient; both "sedikit" and "tidak ada" are pink, to
    /// match the checklist and the illustrated plate assets.
    var plateFill: Color {
        self == .sufficient
            ? Color(red: 0.85, green: 0.93, blue: 0.82)  // soft green
            : Color(red: 0.98, green: 0.85, blue: 0.86)  // soft pink
    }
}
