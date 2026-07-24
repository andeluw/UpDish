//
//  HomeView.swift
//  UpDish
//
//  Created by Andrew Wallace on 14/07/26.
//

import PhotosUI
import SwiftData
import SwiftUI

private struct EvaluationResultRoute: Hashable {
    let evaluation: MealEvaluation
    let imageFileName: String?

    static func == (
        lhs: EvaluationResultRoute,
        rhs: EvaluationResultRoute
    ) -> Bool {
        lhs.evaluation.id == rhs.evaluation.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(evaluation.id)
    }
}

struct HomeView: View {
    @Environment(\.modelContext)
    private var modelContext

    @Query(
        sort: \MealHistoryRecord.analyzedAt,
        order: .reverse
    )
    private var historyRecords: [MealHistoryRecord]

    private let imageStorageService = ImageStorageService()

    @State private var historyViewModel = HistoryViewModel()
    @State private var photoInputViewModel = PhotoInputViewModel()
    @State private var searchText = ""
    @State private var isGuidePresented = false
    @State private var isBottomToolbarReady = false
    @State private var pendingResult: EvaluationResultRoute?
    @State private var activeResult: EvaluationResultRoute?

    @State private var appleIntelligence = AppleIntelligenceMonitor()
    @State private var isAppleIntelligenceAlertPresented = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var photoInput = photoInputViewModel

        NavigationStack {
            VStack(spacing: 0) {
                if appleIntelligence.status.deservesHomeNotice {
                    AppleIntelligenceBanner(
                        status: appleIntelligence.status
                    ) {
                        isAppleIntelligenceAlertPresented = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                Group {
                    if historyRecords.isEmpty {
                        emptyHistoryView
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                    } else {
                        ScrollView {
                            historyContent
                        }
                    }
                }
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Isi Piringku")
            .toolbarTitleDisplayMode(.inlineLarge)
            .searchable(
                text: $searchText,
                prompt: "Cari"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    guideButton
                }
                if isBottomToolbarReady {
                    DefaultToolbarItem(
                        kind: .search,
                        placement: .bottomBar
                    )

                    ToolbarSpacer(
                        .fixed,
                        placement: .bottomBar
                    )

                    ToolbarItem(placement: .bottomBar) {
                        photoSourceMenu
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
            }
            .onAppear {
                guard !isBottomToolbarReady else { return }
                Task { @MainActor in
                    await Task.yield()
                    isBottomToolbarReady = true
                }
            }
            .fullScreenCover(
                isPresented: $photoInput.isCameraPresented,
                onDismiss: {
                    Task {
                        await photoInputViewModel
                            .presentComponentModificationIfNeeded()
                    }
                }
            ) {

                CameraPicker { image in
                    photoInputViewModel.handleCapturedImage(image)
                }
                .ignoresSafeArea()
                .background(.black)
            }
            .sheet(
                isPresented: $photoInput.isComponentModificationPresented,
                onDismiss: {
                    guard let pendingResult else {
                        return
                    }

                    activeResult = pendingResult
                    self.pendingResult = nil
                }
            ) {
                if let mealDraft = photoInput.mealDraft {
                    NavigationStack {
                        ComponentModificationView(
                            draft: mealDraft,
                            selectedImage: photoInputViewModel.selectedImage
                        ) { evaluation, imageFileName in
                            pendingResult = EvaluationResultRoute(
                                evaluation: evaluation,
                                imageFileName: imageFileName
                            )
                        }
                    }
                    .interactiveDismissDisabled()
                    .presentationBackground(Color.background)
                }
            }
            .sheet(
                isPresented: $photoInput.isPhotosPresented,
                onDismiss: {
                    Task {
                        await photoInputViewModel
                            .presentComponentModificationIfNeeded()
                    }
                }
            ) {
                PhotoLibraryPickerView(
                    viewModel: photoInputViewModel
                )
            }
            .sheet(
                isPresented: $isGuidePresented
            ) {
                IsiPiringkuGuideView()
            }
            .overlay {
                if photoInputViewModel.isLoading {
                    loadingOverlay
                }
            }
            .alert(
                "Terjadi Kesalahan",
                isPresented: errorIsPresented
            ) {
                Button("Coba lagi", role: .cancel) {
                    photoInputViewModel.errorMessage = nil
                }
            } message: {
                Text(photoInputViewModel.errorMessage ?? "")
            }
            .navigationDestination(item: $activeResult) { route in
                let image = route.imageFileName.flatMap {
                    imageStorageService.load(named: $0)
                }

                EvaluationResultView(
                    viewModel: EvaluationResultViewModel(
                        evaluation: route.evaluation,
                        mealImage: image,
                        modelContext: modelContext
                    )
                )
            }
            .appleIntelligenceAlert(
                isPresented: $isAppleIntelligenceAlertPresented
            )
            // The user may leave, flip the switch, and come back — re-read the
            // state on return so the banner clears itself.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { appleIntelligence.refresh() }
            }
        }
    }
}

extension HomeView {
    private var guideButton: some View {
        Button {
            isGuidePresented = true
        } label: {
            Image(systemName: "questionmark.circle")
        }
        .accessibilityLabel("Panduan Isi Piringku")
    }

    private var photoSourceMenu: some View {
        PhotoSourceMenu(
            isCameraAvailable: photoInputViewModel.isCameraAvailable,
            onCamera: photoInputViewModel.chooseCamera,
            onPhotoLibrary: photoInputViewModel.choosePhotoLibrary
        )
    }

    private var filteredHistoryRecords: [MealHistoryRecord] {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return historyRecords
        }

        return historyRecords.filter {
            $0.mealName.localizedCaseInsensitiveContains(query)
        }
    }

    private var todayRecords: [MealHistoryRecord] {
        filteredHistoryRecords.filter {
            Calendar.current.isDateInToday($0.analyzedAt)
        }
    }

    private var previousRecords: [MealHistoryRecord] {
        filteredHistoryRecords.filter {
            !Calendar.current.isDateInToday($0.analyzedAt)
        }
    }

    private var historyContent: some View {
        LazyVStack(alignment: .leading, spacing: 24) {
            if !todayRecords.isEmpty {
                historySection(title: "Hari Ini", records: todayRecords)
            }

            if !previousRecords.isEmpty {
                historySection(title: "Sebelumnya", records: previousRecords)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var emptyHistoryView: some View {
        ContentUnavailableView(
            "Belum Ada Riwayat",
            systemImage: "clock.arrow.circlepath",
            description: Text(
                "Yuk, mulai evaluasi makanan pertamamu dengan mengetuk tombol + di kanan bawah."
            )
        )
        .padding(.horizontal, 20)
    }

    private func historySection(
        title: String,
        records: [MealHistoryRecord]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                ForEach(
                    Array(records.enumerated()),
                    id: \.element.id
                ) { index, record in
                    NavigationLink {
                        EvaluationResultView(
                            viewModel: EvaluationResultViewModel(
                                record: record,
                                modelContext: modelContext
                            )
                        )
                    } label: {
                        HistoryCardComponent(
                            record: record,
                            viewModel: historyViewModel
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)

                    if index < records.count - 1 {
                        Rectangle()
                            .fill(Color.textBorder)
                            .frame(height: 1.75)
                            .padding(.horizontal, 12)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color.textBorder,
                        lineWidth: 3
                    )
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black
                .opacity(0.15)
                .ignoresSafeArea()

            ProgressView("Memproses foto...")
                .padding(20)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(
                        cornerRadius: 16
                    )
                )
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: {
                photoInputViewModel.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    photoInputViewModel.errorMessage = nil
                }
            }
        )
    }
}

#Preview {
    let configuration = ModelConfiguration(
        isStoredInMemoryOnly: true
    )

    let container = try! ModelContainer(
        for: MealHistoryRecord.self,
        configurations: configuration
    )

    let previewDate:
        (
            _ daysAgo: Int,
            _ hour: Int,
            _ minute: Int
        ) -> Date = { daysAgo, hour, minute in
            let day =
                Calendar.current.date(
                    byAdding: .day,
                    value: -daysAgo,
                    to: .now
                ) ?? .now

            return Calendar.current.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: day
            ) ?? day
        }

    let firstTodayRecord = MealHistoryRecord(
        mealName: "Nasi Ayam + Sayur + Pepaya",
        overallStatus: .balanced,
        summary: "Semua komponen terpenuhi",
        imageFileName: nil,
        components: [
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
                portionPercentage: 35
            ),
            MealComponent(
                name: "Ayam Panggang",
                category: .protein,
                portionPercentage: 20
            ),
            MealComponent(
                name: "Sayur",
                category: .vegetable,

                portionPercentage: 30
            ),
            MealComponent(
                name: "Pepaya",
                category: .fruit,
                portionPercentage: 15
            ),
        ],
        categoryEvaluations: [
            CategoryEvaluation(
                category: .stapleFood,
                portionPercentage: 35,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .protein,
                portionPercentage: 20,
                status: .sufficient,
                targetPercentage: 17
            ),
            CategoryEvaluation(
                category: .vegetable,
                portionPercentage: 30,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .fruit,
                portionPercentage: 15,
                status: .sufficient,
                targetPercentage: 17
            ),
        ]
    )

    firstTodayRecord.analyzedAt = previewDate(0, 18, 50)

    let secondTodayRecord = MealHistoryRecord(
        mealName: "Nasi Ayam Panggang + Tomat",
        overallStatus: .mostlyBalanced,
        summary: "Buah belum tersedia",
        imageFileName: nil,
        components: [
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
                portionPercentage: 40
            ),
            MealComponent(
                name: "Ayam Panggang",
                category: .protein,
                portionPercentage: 30
            ),
            MealComponent(
                name: "Tomat",
                category: .vegetable,
                portionPercentage: 30
            ),
        ],
        categoryEvaluations: [
            CategoryEvaluation(
                category: .stapleFood,
                portionPercentage: 40,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .protein,
                portionPercentage: 30,
                status: .sufficient,
                targetPercentage: 17
            ),
            CategoryEvaluation(
                category: .vegetable,
                portionPercentage: 30,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .fruit,
                portionPercentage: 0,
                status: .missing,
                targetPercentage: 17
            ),
        ]
    )

    secondTodayRecord.analyzedAt = previewDate(0, 12, 10)

    let thirdTodayRecord = MealHistoryRecord(
        mealName: "Nasi Sayur + Telur Dadar",
        overallStatus: .mostlyBalanced,
        summary: "Buah belum tersedia",
        imageFileName: nil,
        components: [
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
                portionPercentage: 40
            ),
            MealComponent(
                name: "Telur Dadar",
                category: .protein,
                portionPercentage: 25
            ),
            MealComponent(
                name: "Sayur",
                category: .vegetable,
                portionPercentage: 35
            ),
        ],
        categoryEvaluations: [
            CategoryEvaluation(
                category: .stapleFood,
                portionPercentage: 40,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .protein,
                portionPercentage: 25,
                status: .sufficient,
                targetPercentage: 17
            ),
            CategoryEvaluation(
                category: .vegetable,
                portionPercentage: 35,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .fruit,
                portionPercentage: 0,
                status: .missing,
                targetPercentage: 17
            ),
        ]
    )

    thirdTodayRecord.analyzedAt = previewDate(0, 9, 0)

    let firstPreviousRecord = MealHistoryRecord(
        mealName: "Nasi Ikan Panggang + Tumis Kangkung + Pepaya",
        overallStatus: .balanced,
        summary: "Semua komponen terpenuhi",
        imageFileName: nil,
        components: [
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
                portionPercentage: 35
            ),
            MealComponent(
                name: "Ikan Panggang",
                category: .protein,
                portionPercentage: 20
            ),
            MealComponent(
                name: "Tumis Kangkung",
                category: .vegetable,
                portionPercentage: 30
            ),
            MealComponent(
                name: "Pepaya",
                category: .fruit,
                portionPercentage: 15
            ),
        ],
        categoryEvaluations: [
            CategoryEvaluation(
                category: .stapleFood,
                portionPercentage: 35,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .protein,
                portionPercentage: 20,
                status: .sufficient,
                targetPercentage: 17
            ),
            CategoryEvaluation(
                category: .vegetable,
                portionPercentage: 30,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .fruit,
                portionPercentage: 15,
                status: .sufficient,
                targetPercentage: 17
            ),
        ]
    )

    firstPreviousRecord.analyzedAt = previewDate(1, 18, 0)

    let secondPreviousRecord = MealHistoryRecord(
        mealName: "Nasi Ayam Goreng",
        overallStatus: .needsImprovement,
        summary: "Sayur dan buah belum tersedia",
        imageFileName: nil,
        components: [
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
                portionPercentage: 60
            ),
            MealComponent(
                name: "Ayam Goreng",
                category: .protein,
                portionPercentage: 40
            ),
        ],
        categoryEvaluations: [
            CategoryEvaluation(
                category: .stapleFood,
                portionPercentage: 60,
                status: .sufficient,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .protein,
                portionPercentage: 40,
                status: .sufficient,
                targetPercentage: 17
            ),
            CategoryEvaluation(
                category: .vegetable,
                portionPercentage: 0,
                status: .missing,
                targetPercentage: 33
            ),
            CategoryEvaluation(
                category: .fruit,
                portionPercentage: 0,
                status: .missing,
                targetPercentage: 17
            ),
        ]
    )

    secondPreviousRecord.analyzedAt = previewDate(1, 13, 0)

    let records = [
        firstTodayRecord,
        secondTodayRecord,
        thirdTodayRecord,
        firstPreviousRecord,
        secondPreviousRecord,
    ]

    for record in records {
        container.mainContext.insert(record)
    }

    try? container.mainContext.save()

    return HomeView()
        .modelContainer(container)
}
