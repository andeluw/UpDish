//
//  HistoryViewModel.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 16/07/26.
//

import Foundation
import UIKit

@MainActor
@Observable
final class HistoryViewModel {
    /// Fungsi load gambar berdasarkan nama file
    func loadImage(named fileName: String?) -> UIImage? {
        guard let fileName = fileName, !fileName.isEmpty else { return nil }

        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
        guard let fileURL = documentsDirectory?.appendingPathComponent(fileName)
        else { return nil }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }

        return nil
    }

    /// Ambil mealName
    func getMealName(for record: MealHistoryRecord) -> String {
        let trimmed = record.mealName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmed.isEmpty ? "Menu Tanpa Nama" : record.mealName
    }

    /// Ambil tanggal
    func getFormattedDate(for record: MealHistoryRecord) -> String {
        DateFormatterHelper.mealTimestamp(from: record.analyzedAt)
    }

    /// Ambil status
    func getStatus(for record: MealHistoryRecord) -> MealBalanceStatus {
        record.overallStatus
    }

    /// Ambil summary
    func getSummary(for record: MealHistoryRecord) -> String {
        let badCategories = record.categoryEvaluations.filter {
            $0.status.needsImprovement
        }
        
        if badCategories.isEmpty {
            return "Semua komponen terpenuhi"
        }
        let categoryNames = badCategories.map { $0.category.displayName }
        let joinedCategories = categoryNames.joined(separator: ", ")

        return "Kurang: \(joinedCategories)"
    }
}
