//
//  HomeView.swift
//  UpDish
//
//  Created by Andrew Wallace on 14/07/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MealHistoryRecord.analyzedAt, order: .reverse)
    private var records: [MealHistoryRecord]

    @State private var photoInputViewModel = PhotoInputViewModel()
    @State private var searchText = ""
    @State private var isGuidePresented = false
    @State private var isBottomToolbarReady = false
    
    var body: some View {
        @Bindable var photoInput = photoInputViewModel
        
        NavigationStack {
            ScrollView {
                historyContent
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Isi Piringku")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                prompt: "Search"
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
                onDismiss:  {
                    Task {
                        await photoInputViewModel.presentComponentModificationIfNeeded()
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
                isPresented: $photoInput.isComponentModificationPresented
            ) {
                if let mealDraft = photoInput.mealDraft {
                    ComponentModificationView(draft: mealDraft)
                        .interactiveDismissDisabled()
                }
            }
            .sheet(
                isPresented: $photoInput.isPhotosPresented,
                onDismiss: {
                    Task {
                        await photoInputViewModel.presentComponentModificationIfNeeded()
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
                // TODO: Isi Piringku Guide
                Text("Panduan Isi Piringku")
                    .padding()
                
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
                Button("OK", role: .cancel) {
                    photoInputViewModel.errorMessage = nil
                }
            } message: {
                Text(photoInputViewModel.errorMessage ?? "")
            }
        }
    }
}

private extension HomeView {
    var guideButton: some View {
        Button {
            isGuidePresented = true
        } label: {
            Image(systemName: "questionmark.circle")
        }
        .accessibilityLabel("Panduan Isi Piringku")
    }
    
    var photoSourceMenu: some View {
        PhotoSourceMenu(
            isCameraAvailable: photoInputViewModel.isCameraAvailable,
            onCamera: photoInputViewModel.chooseCamera,
            onPhotoLibrary: photoInputViewModel.choosePhotoLibrary
        )
    }
    
    var filteredRecords: [MealHistoryRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return records }
        return records.filter { $0.mealName.localizedCaseInsensitiveContains(query) }
    }

    var historyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hari Ini")
                .font(.title2)
                .fontWeight(.semibold)

            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "Belum Ada Riwayat",
                    systemImage: "clock.arrow.circlepath",
                    description: Text(
                        "Hasil analisis akan muncul di sini."
                    )
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredRecords) { record in
                    NavigationLink {
                        EvaluationResultView(
                            viewModel: EvaluationResultViewModel(
                                evaluation: record.toMealResult().evaluation,
                                modelContext: modelContext
                            )
                        )
                    } label: {
                        historyRow(record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    func historyRow(_ record: MealHistoryRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.mealName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(DateFormatterHelper.mealTimestamp(from: record.analyzedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(record.overallStatus.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(record.overallStatus.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(record.overallStatus.cardBackground)
                .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    var loadingOverlay: some View {
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
    
    var errorIsPresented: Binding<Bool> {
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
