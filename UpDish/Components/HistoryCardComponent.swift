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
                    .frame(width: 75, height: 75)
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
                    .font(.footnote)
                    .fontWeight(.bold)
                    .lineLimit(3)
                Text(viewModel.getFormattedDate(for: record))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.secondary)

                MealStatusChip(status: viewModel.getStatus(for: record))
                    .padding(.vertical, 2)

                Text(viewModel.getSummary(for: record))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
        .environment(\.locale, Locale(identifier: "id"))
    }
    
    private var voiceOverLabel: Text {
        let name = viewModel.getMealName(for: record)
        let date = viewModel.getFormattedDate(for: record).replacingOccurrences(of: "|", with: "tanggal")
        let status = viewModel.getStatus(for: record).displayName
        let summary = viewModel.getSummary(for: record)
        
        let fullText = "\(name). Dianalisis pada jam \(date). Status gizi \(status), \(summary)"
        
        return Text(fullText)
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
        categoryEvaluations: [
            CategoryEvaluation(category: .stapleFood, portionPercentage: 35, status: .sufficient, targetPercentage: 35),
            CategoryEvaluation(category: .protein, portionPercentage: 35, status: .sufficient, targetPercentage: 35),
            CategoryEvaluation(category: .vegetable, portionPercentage: 30, status: .sufficient, targetPercentage: 30)
        ]
    )
    
    HistoryCardComponent(record: mockRecord, viewModel: mockViewModel)
        .padding()
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
}
