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

    /// Spoken form for VoiceOver. The visual format uses a "|" separator, which
    /// a screen reader announces literally, so this uses the locale's own
    /// wording instead ("20 Juli 2026 pukul 22.27").
    private static let spokenFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "id_ID")
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    static func spokenMealTimestamp(from date: Date) -> String {
        spokenFormatter.string(from: date)
    }
}
