//
//  ComponentViewModel.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 13/07/26.
//

import Foundation
import SwiftUI
import Combine

class ComponentViewModel: ObservableObject {
    @Published var components: [MealComponent]
    @Published var mealName: String
    
    init(
        mealName: String = "Makanan",
        components: [MealComponent] = []
    ) {
        self.mealName = mealName
        self.components = components
    }
    
    convenience init(draft: MealDraft) {
        self.init(
            mealName: draft.mealName,
            components: draft.components
        )
    }
    
    /// Fungsi untuk menambah komponen
    func addComponent(portionPercentage: Int = 1) {
        var newIndex = 1
        
        while components.contains(where: { $0.name.lowercased() == "komponen baru \(newIndex)".lowercased() }) {
            newIndex += 1
        }
        
        let safeName = "Komponen Baru \(newIndex)"
        let newComponent = MealComponent(name: safeName, portionPercentage: portionPercentage)
        components.append(newComponent)
    }
    
    /// Fungsi untuk menghapus komponen
    func removeComponent(at offsets: IndexSet) {
        components.remove(atOffsets: offsets)
    }
    
    /// Fungsi untuk mengubah nama komponen berdasarkan ID uniknya
    func updateName(for id: UUID, to newName: String) {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let index = components.firstIndex(where: { $0.id == id }) else { return }
        
        if components.contains(where: { $0.id != id && $0.name.lowercased() == newName.lowercased() }) {
            return
        }
        
        components[index].name = newName
    }
    
    /// Fungsi untuk mengubah porsi/persentase secara spesifik
    func updateProportion(for id: UUID, to newProportion: Int) {
        guard let index = components.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let cappedProportion = min(100, max(1, newProportion))
        components[index].portionPercentage = cappedProportion
    }
    
    /// Menjalankan evaluasi Isi Piringku pada komponen yang sudah dikoreksi.
    ///
    /// Deteksi hanya mengembalikan nama dan porsi tanpa kelompok Isi Piringku,
    /// jadi komponen diklasifikasikan dulu. Tanpa langkah ini `category` tetap
    /// nil dan seluruh piring dihitung kosong.
    @MainActor
    func makeEvaluation(
        classifier: MealComponentClassifier = .init(),
        using service: IsiPiringkuEvaluationService = .init()
    ) async -> MealEvaluation {
        // Simpan hasil klasifikasi agar ikut tersimpan di riwayat.
        components = await classifier.classify(components)

        return service.evaluate(
            mealName: mealName.trimmingCharacters(in: .whitespacesAndNewlines),
            components: components
        )
    }


    /// Validasi kelayakan piring sebelum lanjut ke evaluasi
    var isDishValid: Bool {
            let isPercentageValid = remainingPercentage == 0
            let isNameValid = !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            let areComponentsValid = !components.isEmpty && components.allSatisfy {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return isPercentageValid && isNameValid && areComponentsValid
        }
    
    /// Menghitung sisa komposisi
    var remainingPercentage: Int {
        let total = components.reduce(0) { $0 + $1.portionPercentage }
        return 100 - total
    }
}
