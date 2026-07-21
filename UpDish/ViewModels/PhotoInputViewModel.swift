//
//  PhotoInputViewModel.swift
//  UpDish
//
//  Created by Andrew Wallace on 14/07/26.
//

import Observation
import PhotosUI
import SwiftUI
import UIKit
import FirebaseCore

@MainActor
@Observable
final class PhotoInputViewModel {
    // Selected result
    var selectedImage: UIImage?  // final image
    var pickerItems: [PhotosPickerItem] = []  // temporary item from photo picker
    var mealDraft: MealDraft?

    // Presentation states
    var isCameraPresented = false
    var isPhotosPresented = false
    var isComponentModificationPresented = false

    // Loading and error states
    var isLoading = false
    var errorMessage: String?

    private var shouldOpenComponentModification = false

    // Meal detection
    private let mealDetectionService: any MealDetectionService

    init(
        mealDetectionService: any MealDetectionService
    ) {
        self.mealDetectionService = mealDetectionService
    }

    convenience init() {
        #if DEBUG
        if FirebaseApp.app() == nil {
            self.init(
                mealDetectionService: MockMealDetectionService()
            )
        } else {
            self.init(
                mealDetectionService: FirebaseAIMealDetectionService()
            )
        }
        #else
        self.init(
            mealDetectionService: MockMealDetectionService()
        )
        #endif
    }

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
    func presentComponentModificationIfNeeded() async {
        guard shouldOpenComponentModification else { return }
        guard let selectedImage else { return }

        shouldOpenComponentModification = false
        mealDraft = nil
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            mealDraft = try await mealDetectionService.detect(
                from: selectedImage
            )

            isComponentModificationPresented = true
        } catch {
            shouldOpenComponentModification = true

            if let detectionError = error as? MealDetectionError {
                errorMessage = detectionError.errorDescription
            } else {
                errorMessage =
                    error.localizedDescription.isEmpty
                    ? "Makanan belum dapat dianalisis. Periksa koneksi dan coba lagi."
                    : error.localizedDescription
            }
        }
    }

    // MARK: - Reset
    func reset() {
        selectedImage = nil
        pickerItems = []
        mealDraft = nil

        shouldOpenComponentModification = false

        isCameraPresented = false
        isPhotosPresented = false
        isComponentModificationPresented = false

        isLoading = false
        errorMessage = nil
    }
}
