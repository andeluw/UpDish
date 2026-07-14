//
//  ContentView.swift
//  UpDish
//
//  Temporary demo entry point: lets you open the feedback screen with sample
//  meals (matching the mockups) while the camera / detection flow is built by
//  the other team. Replace with the real navigation later.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Contoh Makanan") {
                    NavigationLink("Nasi Ayam Panggang + Tomat") {
                        EvaluationResultView(viewModel: .sampleCukupBaik)
                    }
                    NavigationLink("Nasi Ayam Goreng") {
                        EvaluationResultView(viewModel: .samplePerluDiperbaiki)
                    }
                    NavigationLink("Piring Lengkap (Baik)") {
                        EvaluationResultView(viewModel: .sampleBaik)
                    }
                }
            }
            .navigationTitle("UpDish")
        }
    }
}

private extension EvaluationResultViewModel {
    static var sampleCukupBaik: EvaluationResultViewModel {
        .init(
            foodName: "Nasi Ayam Panggang + Tomat",
            components: [
                MealComponent(name: "Nasi", category: .stapleFood, portionPercentage: 36),
                MealComponent(name: "Ayam Panggang", category: .protein, portionPercentage: 30),
                MealComponent(name: "Tomat", category: .vegetable, portionPercentage: 34)
            ]
        )
    }

    static var samplePerluDiperbaiki: EvaluationResultViewModel {
        .init(
            foodName: "Nasi Ayam Goreng",
            components: [
                MealComponent(name: "Nasi", category: .stapleFood, portionPercentage: 60),
                MealComponent(name: "Ayam Goreng", category: .protein, portionPercentage: 40)
            ]
        )
    }

    static var sampleBaik: EvaluationResultViewModel {
        .init(
            foodName: "Nasi Ayam, Sayur, dan Buah",
            components: [
                MealComponent(name: "Nasi", category: .stapleFood, portionPercentage: 34),
                MealComponent(name: "Ayam", category: .protein, portionPercentage: 16),
                MealComponent(name: "Brokoli", category: .vegetable, portionPercentage: 34),
                MealComponent(name: "Pisang", category: .fruit, portionPercentage: 16)
            ]
        )
    }
}

#Preview {
    ContentView()
}
