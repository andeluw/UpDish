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
    @Published var components: [MealComponent] = []
    @Published var mealName: String = "Makanan"
    
    /// Fungsi untuk menambah komponen
    func addComponent(category: FoodCategory, portionPercentage: Int = 1) {
        var newIndex = 1
        
        while components.contains(where: { $0.name.lowercased() == "komponen baru \(newIndex)".lowercased() }) {
            newIndex += 1
        }
        
        let safeName = "Komponen Baru \(newIndex)"
        let newComponent = MealComponent(name: safeName, category: category, portionPercentage: portionPercentage)
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
    func updateProportion(for name: String, to newProportion: Int) {
        guard let index = components.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) else {
            return
        }
        
        let cappedProportion = min(100, max(1, newProportion))
        components[index].portionPercentage = cappedProportion
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
