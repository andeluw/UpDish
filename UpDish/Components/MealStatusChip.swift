//
//  MealStatusChip.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 17/07/26.
//

import SwiftUI

struct MealStatusChip: View {
    let status: MealBalanceStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(textColor, lineWidth: 1.5))
    }

    private var textColor: Color {
        switch status {
        case .balanced:
            return .seimbang
        case .mostlyBalanced:
            return .cukupBaik
        case .needsImprovement:
            return .perluDilengkapi
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .balanced:
            return .seimbangBackground
        case .mostlyBalanced:
            return .cukupBaikBackground
        case .needsImprovement:
            return .perluDilengkapiBackground
        }
    }
}
