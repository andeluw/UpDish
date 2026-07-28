//
//  HistoryCardComponent.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 16/07/26.
//

import SwiftUI

struct HistoryCardComponent: View {
    let record: MealHistoryRecord
    let viewModel: HistoryViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let dynamicLayout =
            dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 16))

        dynamicLayout {
            Group {
                if let uiImage = viewModel.loadImage(
                    named: record.imageFileName
                ) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color(.systemGray6)
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(
                maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 75,
                minHeight: dynamicTypeSize.isAccessibilitySize ? 150 : 75,
                maxHeight: dynamicTypeSize.isAccessibilitySize ? 150 : 75
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            HStack(alignment: .center, spacing: 12) {
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
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(voiceOverLabel)
                .environment(\.locale, Locale(identifier: "id"))
    }

    private var voiceOverLabel: Text {
        let name = viewModel.getMealName(for: record)
        let date = viewModel.getFormattedDate(for: record).replacingOccurrences(
            of: "|",
            with: "tanggal"
        )
        let status = viewModel.getStatus(for: record).displayName
        let summary = viewModel.getSummary(for: record)

        let fullText =
            "\(name). Dianalisis pada jam \(date). Status gizi \(status), \(summary)"

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
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
                portionPercentage: 35
            ),
            MealComponent(
                name: "Ayam Panggang",
                category: .protein,
                portionPercentage: 35
            ),
            MealComponent(
                name: "Sayur & Pepaya",
                category: .vegetable,
                portionPercentage: 30
            ),
        ],
        categoryEvaluations: [
            CategoryEvaluation(
                category: .stapleFood,
                portionPercentage: 35,
                status: .sufficient,
                targetPercentage: 35
            ),
            CategoryEvaluation(
                category: .protein,
                portionPercentage: 35,
                status: .sufficient,
                targetPercentage: 35
            ),
            CategoryEvaluation(
                category: .vegetable,
                portionPercentage: 30,
                status: .sufficient,
                targetPercentage: 30
            ),
        ]
    )

    HistoryCardComponent(record: mockRecord, viewModel: mockViewModel)
        .padding()
}

#Preview("Kondisi Kekurangan Zat Gizi") {
    let mockViewModel = HistoryViewModel()

    let mockRecord = MealHistoryRecord(
        mealName: "Nasi Ayam Panggang + Tomat",
        overallStatus: .needsImprovement,
        summary: "",
        imageFileName: "NasiAyamSayurPepaya",
        components: [
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam Panggang",
                category: .protein,
                portionPercentage: 50
            ),
        ],
        categoryEvaluations: [
            CategoryEvaluation(
                category: .stapleFood,
                portionPercentage: 50,
                status: .missing,
                targetPercentage: 40
            ),
            CategoryEvaluation(
                category: .protein,
                portionPercentage: 50,
                status: .missing,
                targetPercentage: 30
            ),
            CategoryEvaluation(
                category: .fruit,
                portionPercentage: 0,
                status: .missing,
                targetPercentage: 30
            ),
        ]
    )

    HistoryCardComponent(record: mockRecord, viewModel: mockViewModel)
        .padding()
}
