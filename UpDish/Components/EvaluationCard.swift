//
//  EvaluationCard.swift
//  UpDish
//
//  The tinted feedback banner ("Cukup Baik", "Perlu Diperbaiki", ...) with
//  a lightbulb icon, driven by the overall status colour.
//

import SwiftUI

struct EvaluationCard: View {
    let status: MealBalanceStatus
    let feedback: FeedbackText

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status.iconName)
                .foregroundStyle(status.accentColor)
                .font(.system(size: 20, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text(feedback.headline)
                    .font(.headline)
                    .foregroundStyle(status.accentColor)
                Text(feedback.body)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(status.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status.accentColor, lineWidth: 1.5)
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        EvaluationCard(
            status: .mostlyBalanced,
            feedback: FeedbackText(
                headline: "Cukup Baik",
                body: "Komposisi makanan sudah cukup seimbang, tinggal lengkapi dengan buah."
            )
        )
        EvaluationCard(
            status: .needsImprovement,
            feedback: FeedbackText(
                headline: "Perlu Diperbaiki",
                body: "Komposisi makanan belum seimbang. Yuk, lengkapi dengan sayur dan buah."
            )
        )
    }
    .padding()
}
