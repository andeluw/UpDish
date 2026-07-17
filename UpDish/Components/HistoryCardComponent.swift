//
//  HistoryCardComponent.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 16/07/26.
//

import SwiftUI

struct HistoryCardComponent: View {
    let record: MealHistoryRecord
    var viewModel: HistoryViewModel

    var body: some View {
        HStack (alignment: .top, spacing: 12) {
            if let uiImage = viewModel.loadImage(named: record.imageFileName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.getMealName(for: record))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                Text(viewModel.getFormattedDate(for: record))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                MealStatusChip(status: viewModel.getStatus(for: record))
                    .padding(.vertical, 2)

                Text(viewModel.getSummary(for: record))
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Kondisi Gizi Seimbang") {
    let mockViewModel = HistoryViewModel()
    
    let mockRecord = MealHistoryRecord(
        mealName: "Nasi Ayam + Sayur + Pepaya",
        overallStatus: .balanced,
        summary: "",
        imageFileName: "NasiAyamSayurPepaya",
        components: [
            MealComponent(name: "Nasi Putih", category: .stapleFood, portionPercentage: 35),
            MealComponent(name: "Ayam Panggang", category: .protein, portionPercentage: 35),
            MealComponent(name: "Sayur & Pepaya", category: .vegetable, portionPercentage: 30)
        ],
        // 🌟 SEMUA CUKUP: Array kosong / status .sufficient membuat VM mengoutput "Semua komponen terpenuhi"
        categoryEvaluations: [
            CategoryEvaluation(category: .stapleFood, portionPercentage: 35, status: .sufficient, targetPercentage: 35),
            CategoryEvaluation(category: .protein, portionPercentage: 35, status: .sufficient, targetPercentage: 35),
            CategoryEvaluation(category: .vegetable, portionPercentage: 30, status: .sufficient, targetPercentage: 30)
        ]
    )
    
    HistoryCardComponent(record: mockRecord, viewModel: mockViewModel)
        .padding()
        .previewLayout(.sizeThatFits)
}

#Preview("Kondisi Kekurangan Zat Gizi") {
    let mockViewModel = HistoryViewModel()
    
    let mockRecord = MealHistoryRecord(
        mealName: "Nasi Ayam Panggang + Tomat",
        overallStatus: .mostlyBalanced,
        summary: "",
        imageFileName: "NasiAyamSayurPepaya",
        components: [
            MealComponent(name: "Nasi Putih", category: .stapleFood, portionPercentage: 50),
            MealComponent(name: "Ayam Panggang", category: .protein, portionPercentage: 50)
        ],
        categoryEvaluations: [
            CategoryEvaluation(category: .stapleFood, portionPercentage: 50, status: .sufficient, targetPercentage: 40),
            CategoryEvaluation(category: .protein, portionPercentage: 50, status: .sufficient, targetPercentage: 30),
            CategoryEvaluation(category: .fruit, portionPercentage: 0, status: .missing, targetPercentage: 30)
        ]
    )
    
    HistoryCardComponent(record: mockRecord, viewModel: mockViewModel)
        .padding()
        .previewLayout(.sizeThatFits)
}
