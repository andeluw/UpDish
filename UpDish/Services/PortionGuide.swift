//
//  PortionGuide.swift
//  UpDish
//
//  Indonesian household-measure (Ukuran Rumah Tangga / URT) portions for the
//  recommendation options, based on the Ministry of Health's food-portion
//  vocabulary (centong, potong, buah, butir, ekor, mangkuk, lembar, sendok).
//
//  Why this exists: the Foundation Model writes portions in ENGLISH ("1 scoop
//  of rice"), which Apple's translator then renders with generic words —
//  "sendok" for rice, where the correct serving word is "centong". Indonesian
//  serving vessels have no English equivalent for the model to produce, so no
//  amount of prompt tuning fixes it. Instead we let the model choose the food
//  and assign the portion HERE, deterministically, from the food name.
//
//  Rules baked in: specific unit per food, plain and familiar, never grams, and
//  never hand-based units ("segenggam", "sekepal") which read as imprecise.
//

import Foundation

enum PortionGuide {

    /// The household portion for a recommended food. Tries the food name against
    /// the keyword table first (so "Nasi Merah" and "Tumis Bayam" get their own
    /// units), then falls back to a sensible default for the group, so EVERY
    /// option ends up with a concrete, familiar measure.
    static func portion(for name: String, category: FoodCategory) -> String {
        let lowered = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Only match within the food's own group. This is what prevents the
        // substring traps that bite plain string matching: "bayam" contains
        // "ayam", "kubis" contains "ubi" — scoping to the category means a
        // vegetable can never pick up a protein's or staple's unit.
        if let match = keywords[category]?.first(where: { lowered.contains($0.match) }) {
            return match.portion
        }
        return categoryDefault[category] ?? "1 porsi sedang"
    }

    /// Fallback when the specific food isn't listed — one safe unit per group.
    private static let categoryDefault: [FoodCategory: String] = [
        .stapleFood: "1 centong",
        .protein: "1 potong sedang",
        .vegetable: "1 mangkuk",
        .fruit: "1 potong sedang"
    ]

    /// Per-group keyword tables, matched in order so the most specific phrase
    /// wins ("nasi merah" before "nasi"). Only the food's own group is
    /// searched, so cross-group substring collisions can't happen.
    private static let keywords: [FoodCategory: [(match: String, portion: String)]] = [
        .stapleFood: [
            ("nasi merah", "1 centong"),
            ("nasi", "1 centong"),
            ("bubur", "1 mangkuk"),
            ("kentang", "2 buah sedang"),
            ("jagung", "1 buah sedang"),
            ("singkong", "1 potong sedang"),
            ("talas", "1 potong sedang"),
            ("ubi", "1 buah sedang"),
            ("roti", "2 lembar"),
            ("bihun", "1 mangkuk"),
            ("mie", "1 mangkuk"),
            ("makaroni", "1 mangkuk"),
            ("pasta", "1 mangkuk"),
            ("lontong", "1 potong"),
            ("ketupat", "1 potong"),
            ("oat", "3 sendok makan"),
            ("sagu", "1 centong")
        ],
        .protein: [
            ("ayam", "1 potong sedang"),
            ("telur", "1 butir"),
            ("tempe", "2 potong"),
            ("tahu", "2 potong"),
            ("udang", "5 ekor sedang"),
            ("cumi", "1 potong sedang"),
            ("bakso", "4 butir"),
            ("teri", "2 sendok makan"),
            ("daging", "1 potong sedang"),
            ("sapi", "1 potong sedang"),
            ("kambing", "1 potong sedang"),
            ("kacang", "2 sendok makan"),
            ("ikan", "1 potong sedang")
        ],
        .vegetable: [
            // Served by the bowl, so the default already fits most; these are
            // the exceptions.
            ("lalapan", "1 piring kecil")
        ],
        .fruit: [
            ("pisang", "1 buah"),
            ("pepaya", "1 potong sedang"),
            ("semangka", "1 potong sedang"),
            ("melon", "1 potong sedang"),
            ("apel", "1 buah"),
            ("jeruk", "2 buah"),
            ("mangga", "1 buah sedang"),
            ("anggur", "1 mangkuk kecil"),
            ("alpukat", "1/2 buah"),
            ("salak", "3 buah"),
            ("pir", "1 buah")
        ]
    ]
}
