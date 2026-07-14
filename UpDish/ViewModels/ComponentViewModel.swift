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
    
    /// Fungsi untuk menambah komponen
    func addComponent(name: String, category: FoodCategory, portionPercentage: Int = 1) {
        guard !name.isEmpty else { return }
        
        if (components.contains(where: {$0.name.lowercased() == name.lowercased() })) {
            return
        }
        
        let newComponent = MealComponent(name: name, category: category, portionPercentage: portionPercentage)
        components.append(newComponent)
    }
    
    /// Fungsi untuk menghapus komponen
    func removeComponent(at offsets: IndexSet) {
        components.remove(atOffsets: offsets)
    }
    
    /// Fungsi untuk mengubah nama komponen berdasarkan ID uniknya
    func updateName(for id: UUID, to newName: String) {
        guard !newName.isEmpty else { return }
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
        if components.isEmpty { return false }
        let totalProportion = components.reduce(0) { $0 + $1.portionPercentage }
        return totalProportion == 100
    }
}
