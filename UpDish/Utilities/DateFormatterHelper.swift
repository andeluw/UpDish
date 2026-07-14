//
//  DateFormatterHelper.swift
//  UpDish
//
//  Small generic helper — formats the meal timestamp like "13.00 | 15 Mei 2026".
//

import Foundation

enum DateFormatterHelper {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateFormat = "HH.mm | d MMM yyyy"
        return f
    }()

    static func mealTimestamp(from date: Date) -> String {
        formatter.string(from: date)
    }
}
