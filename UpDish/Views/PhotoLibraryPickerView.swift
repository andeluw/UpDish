//
//  PhotoLibraryPickerView.swift
//  UpDish
//
//  Created by Andrew Wallace on 15/07/26.
//

import SwiftUI
import PhotosUI

struct PhotoLibraryPickerView: View {
    @Bindable var viewModel: PhotoInputViewModel
    
    var body: some View {
        NavigationStack {
            PhotosPicker(
                "Pilih Foto",
                selection: $viewModel.pickerItems,
                maxSelectionCount: 1,
                selectionBehavior: .continuous,
                matching: .images
            )
            .photosPickerStyle(.inline)
            .photosPickerDisabledCapabilities(.selectionActions)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Pilih Foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.cancelPhotoLibrary()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Batal")
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.confirmSelectedPhoto()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .tint(Color.accent)
                    .disabled(viewModel.pickerItems.isEmpty || viewModel.isLoading)
                    .accessibilityLabel("Gunakan foto")
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }
}
