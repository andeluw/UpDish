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
    
    init(record: MealHistoryRecord) {
        _viewModel = State(
            initialValue: EvaluationResultViewModel(
                record: record
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                mealImage

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.foodName)
                        .font(.title2.bold())
                        .accessibilityLabel(viewModel.foodName)
                    Text(viewModel.dateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(viewModel.dateAccessibilityText)
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
                    .accessibilityHidden(true)
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
        let text = "Hasil analisis AI merupakan estimasi dan mungkin tidak selalu akurat. "
            + "Jika terdapat komponen yang kurang tepat, Anda dapat mengubahnya "
            + "pada halaman komponen makanan."

        return Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
    }

    /// Shown in the feedback slot while the on-device model + translation run,
    /// so the user sees clear progress instead of placeholder/fallback text.
    private var guidanceLoadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Self.loadingAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Menganalisis dengan AI…")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Self.loadingAccent)
                Text("Menyusun masukan dan rekomendasi untukmu.")
                    .font(.caption)
                    .foregroundStyle(Self.loadingBody)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Self.loadingBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Self.loadingBorder, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Menganalisis dengan AI. Menyusun masukan dan rekomendasi untukmu.")
    }

    // Neutral palette for the AI loading state — it stands in for the feedback
    // card before a verdict's colours are known, so it stays greyscale.
    private static let loadingAccent = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)      // #4D4D4D
    private static let loadingBody = Color.black                                                   // #000000
    private static let loadingBorder = Color(red: 204 / 255, green: 204 / 255, blue: 204 / 255)   // #CCCCCC
    private static let loadingBackground = Color(red: 239 / 255, green: 239 / 255, blue: 239 / 255) // #EFEFEF

    private var mealImage: some View {
        Group {
            if let image = viewModel.mealImage {
                Image(uiImage: image)
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
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel("Foto \(viewModel.foodName)")
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
