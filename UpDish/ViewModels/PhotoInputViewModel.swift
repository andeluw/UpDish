//
//  PhotoInputViewModel.swift
//  UpDish
//
//  Created by Andrew Wallace on 14/07/26.
//

import SwiftUI
import Observation
import PhotosUI

@MainActor
@Observable
final class PhotoInputViewModel {
    // Selected result
    var selectedImage: UIImage? // final image
    var pickerItems: [PhotosPickerItem] = [] // temporary item from photo picker
    
    // Presentation states
    var isCameraPresented = false
    var isPhotosPresented = false
    var isComponentModificationPresented = false
    
    // Loading and error states
    var isLoading = false
    var errorMessage: String?
    
    private var shouldOpenComponentModification = false
    
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private func setSelectedImage(_ image: UIImage) {
        selectedImage = image
        errorMessage = nil
        shouldOpenComponentModification = true
    }
    
    // MARK: - Camera
    func chooseCamera() {
        guard isCameraAvailable else {
            errorMessage = "Kamera tidak tersedia di perangkat ini."
            return
        }
        
        shouldOpenComponentModification = false
        errorMessage = nil
        isCameraPresented = true
    }
    
    func handleCapturedImage(_ image: UIImage) {
        setSelectedImage(image)
    }
    
    // MARK: - Photo Library
    func choosePhotoLibrary() {
        pickerItems = []
        shouldOpenComponentModification = false
        errorMessage = nil
        isPhotosPresented = true
    }
    
    func cancelPhotoLibrary() {
        pickerItems = []
        shouldOpenComponentModification = false
        isPhotosPresented = false
    }
    
    func confirmSelectedPhoto() async {
        guard let selectedItem = pickerItems.first else { return }
        
        let didLoadSuccessfully = await loadSelectedPhoto(from: selectedItem)
        
        if didLoadSuccessfully {
            isPhotosPresented = false
        }
    }

    func loadSelectedPhoto(
        from item: PhotosPickerItem
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
            self.pickerItems = []
        }
        
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                errorMessage = "Gagal memuat gambar. Coba pilih foto lain."
                return false
            }
            
            setSelectedImage(image)
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = "Gagal memuat gambar. Coba pilih foto lain."
            return false
        }
    }
    
    // MARK: - Component Modification
    func presentComponentModificationIfNeeded() {
        guard shouldOpenComponentModification else { return }
        
        shouldOpenComponentModification = false
        isComponentModificationPresented = true
    }
    
    // MARK: - Reset
    func reset() {
        selectedImage = nil
        pickerItems = []
        shouldOpenComponentModification = false
        errorMessage = nil
    }
}
