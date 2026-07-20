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

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.foodName)
                        .font(.title2.bold())
                    Text(viewModel.dateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .center, spacing: 20) {
                    IsiPiringkuPlateView(evaluations: viewModel.evaluation.categoryEvaluations)
                    CategoryChecklistView(evaluations: viewModel.evaluation.categoryEvaluations)
                    Spacer(minLength: 0)
                }

                if viewModel.isGeneratingGuidance {
                    guidanceLoadingCard
                } else if let feedback = viewModel.feedback {
                    EvaluationCard(
                        status: viewModel.evaluation.overallStatus,
                        feedback: feedback
                    )
                }

                if !viewModel.isGeneratingGuidance, let recommendation = viewModel.recommendation {
                    RecommendationCard(
                        recommendation: recommendation,
                        status: viewModel.evaluation.overallStatus
                    )
                }

                disclaimer

                #if DEBUG
                Label(viewModel.guidanceSource.rawValue, systemImage: "ladybug.fill")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                #endif
            }
            .padding(20)
        }
        .background(Color.background.ignoresSafeArea())
        .navigationTitle("Detail Isi Piringku")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        #if canImport(Translation)
        .translationTask(viewModel.translationConfig) { session in
            await viewModel.translate(using: session)
        }
        #endif
    }

    /// Closing note that sets expectations about the AI output and points the
    /// user back to the component screen if a detection was wrong.
    private var disclaimer: some View {
        Text(
            "Hasil analisis AI merupakan estimasi dan mungkin tidak selalu akurat. "
            + "Jika terdapat komponen yang kurang tepat, Anda dapat mengubahnya "
            + "pada halaman komponen makanan."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Shown in the feedback slot while the on-device model + translation run,
    /// so the user sees clear progress instead of placeholder/fallback text.
    private var guidanceLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 2) {
                Text("Menganalisis dengan AI…")
                    .font(.subheadline.weight(.medium))
                Text("Menyusun masukan dan rekomendasi untukmu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
