//
//  EvaluationResultView.swift
//  UpDish
//
//  Detail Isi Piringku — the feedback screen. Arranges the reusable
//  Components; the ViewModel holds the state and the Services do the logic.
//

import SwiftUI
#if canImport(Translation)
import Translation
#endif

struct EvaluationResultView: View {
    @State private var viewModel: EvaluationResultViewModel

    init(viewModel: EvaluationResultViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                mealImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.dateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(viewModel.foodName)
                        .font(.title2.bold())
                }

                EvaluationCard(
                    status: viewModel.evaluation.overallStatus,
                    feedback: viewModel.feedback
                )

                if viewModel.isGeneratingGuidance {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Menyusun saran dari AI…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Komposisi Isi Piringku")
                    .font(.headline)

                HStack(alignment: .center, spacing: 20) {
                    IsiPiringkuPlateView(evaluations: viewModel.evaluation.categoryEvaluations)
                    CategoryChecklistView(evaluations: viewModel.evaluation.categoryEvaluations)
                    Spacer(minLength: 0)
                }

                if let recommendation = viewModel.recommendation {
                    RecommendationCard(
                        recommendation: recommendation,
                        status: viewModel.evaluation.overallStatus
                    )
                }
            }
            .padding(20)
        }
        .navigationTitle("Detail Isi Piringku")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        #if canImport(Translation)
        .translationTask(viewModel.translationConfig) { session in
            await viewModel.translate(using: session)
        }
        #endif
    }

    @ViewBuilder
    private var mealImage: some View {
        Group {
            if let asset = viewModel.imageAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle().fill(Color(.secondarySystemBackground))
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Cukup Baik") {
    NavigationStack {
        EvaluationResultView(
            viewModel: EvaluationResultViewModel(
                foodName: "Nasi Ayam Panggang + Tomat",
                components: [
                    MealComponent(name: "Nasi", category: .stapleFood, portionPercentage: 36),
                    MealComponent(name: "Ayam Panggang", category: .protein, portionPercentage: 30),
                    MealComponent(name: "Tomat", category: .vegetable, portionPercentage: 34)
                ]
            )
        )
    }
}

#Preview("Perlu Diperbaiki") {
    NavigationStack {
        EvaluationResultView(
            viewModel: EvaluationResultViewModel(
                foodName: "Nasi Ayam Goreng",
                components: [
                    MealComponent(name: "Nasi", category: .stapleFood, portionPercentage: 60),
                    MealComponent(name: "Ayam Goreng", category: .protein, portionPercentage: 40)
                ]
            )
        )
    }
}
