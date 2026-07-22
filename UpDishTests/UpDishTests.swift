//
//  UpDishTests.swift
//  UpDishTests
//
//  Created by Andrew Wallace on 10/07/26.
//

import Foundation
import Testing

@testable import UpDish

@Suite("Component Modification & Validation Tests")
struct UpDishTests {

    @Test("Remove: Menghapus komponen yang salah terdeteksi")
    func testRemoveComponent() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 40
            ),
            MealComponent(
                name: "Ayam Goreng",
                portionPercentage: 30
            ),
            MealComponent(
                name: "Telur",
                portionPercentage: 30
            ),
        ]

        vm.removeComponent(at: IndexSet(integer: 2))

        #expect(vm.components.count == 2)
        #expect(vm.components[0].name == "Nasi")
        #expect(vm.components[1].name == "Ayam Goreng")
        #expect(!vm.components.contains(where: { $0.name == "Telur" }))
    }

    @Test("Add component appends a structurally empty component to trigger UI placeholder")
    func testAddComponentAppendsEmptyState() {
        let viewModel = ComponentViewModel()
        viewModel.components = [
            MealComponent(name: "Nasi", category: .stapleFood, portionPercentage: 50),
            MealComponent(name: "Ayam Goreng", category: .protein, portionPercentage: 40)
        ]
        
        viewModel.addComponent(portionPercentage: 1)
        
        #expect(viewModel.components.count == 3, "Komponen harus bertambah menjadi 3")
        
        guard let newlyAdded = viewModel.components.last else {
            Issue.record("Komponen gagal ditambahkan")
            return
        }
        
        #expect(newlyAdded.name.isEmpty, "Nama komponen baru harus berupa string kosong")
        #expect(newlyAdded.portionPercentage == 1, "Persentase porsi default harus 1")
    }

    @Test("Edge Case: Validasi gagal jika daftar makanan kosong")
    func testEmptyDishValidation() {
        let vm = ComponentViewModel()
        vm.components = []

        #expect(vm.isDishValid == false)
    }

    @Test("Edit Proportion: Validasi berhasil jika total porsi tepat 100%")
    func testValidTotalProportion() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam",
                portionPercentage: 50
            ),
        ]
        
        let nasiID = vm.components[0].id
        let ayamID = vm.components[1].id

        vm.updateProportion(for: nasiID, to: 30)
        vm.updateProportion(for: ayamID, to: 20)
        vm.addComponent(portionPercentage: 50)

        if let newComponentID = vm.components.last?.id {
            vm.updateName(for: newComponentID, to: "Sayur")
        }

        #expect(vm.remainingPercentage == 0)
        #expect(vm.isDishValid == true)
    }

    @Test("Underflow: Validasi gagal jika total kurang dari 100%")
    func testUnderflowProportion() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 30
            ),
            MealComponent(
                name: "Ayam",
                portionPercentage: 20
            ),
        ]

        #expect(vm.isDishValid == false)
    }

    @Test("Overflow: Validasi gagal jika total lebih dari 100%")
    func testOverflowProportion() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam",
                portionPercentage: 30
            ),
            MealComponent(
                name: "Bayam",
                portionPercentage: 30
            ),
        ]

        #expect(vm.isDishValid == false)
    }

    @Test(
        "Remove & Recalculate: Status menjadi tidak valid setelah komponen dihapus"
    )
    func testRemoveAndRecalculate() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 40
            ),
            MealComponent(
                name: "Ayam",
                portionPercentage: 30
            ),
            MealComponent(
                name: "Telur",
                portionPercentage: 30
            ),
        ]

        vm.removeComponent(at: IndexSet(integer: 2))

        #expect(vm.isDishValid == false)
    }

    @Test("Negative Value: Menolak nilai minus dan mengunci di batas minimum")
    func testNegativeProportionCapping() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam",
                portionPercentage: 50
            ),
        ]
        
        let ayamID = vm.components[1].id
        vm.updateProportion(for: ayamID, to: -20)

        #expect(vm.components[1].portionPercentage >= 0)
    }

    @Test("Huge Value: Memotong nilai yang lebih dari 100% menjadi tepat 100%")
    func testHugeProportionCapping() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 50
            )
        ]

        let nasiID = vm.components[0].id
        vm.updateProportion(for: nasiID, to: 120)

        #expect(vm.components[0].portionPercentage == 100)
    }

    @Test(
        "Zero Value: Mengunci nilai input 0% agar tetap berada di batas minimum 1%"
    )
    func testZeroProportionCapping() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                portionPercentage: 99
            ),
            MealComponent(
                name: "Ayam",
                portionPercentage: 1
            ),
        ]
        
        let ayamID = vm.components[1].id
        vm.updateProportion(for: ayamID, to: 0)

        #expect(vm.components[1].portionPercentage == 1)
    }

    @Test("Edit Name: Mengubah nama komponen yang sudah ada")
    func testEditComponentName() {
        let vm = ComponentViewModel()
        
        let component = MealComponent(
            name: "Ayam Goreng",
            portionPercentage: 50
        )

        vm.components = [component]

        vm.updateName(for: component.id, to: "Ayam Bakar")

        #expect(vm.components[0].name == "Ayam Bakar")
        #expect(vm.components[0].portionPercentage == 50)
    }

    @Test(
        "Edit Name Duplicate: Menolak perubahan nama jika nama baru sudah ada di piring"
    )
    func testEditComponentNameDuplicate() {
        let vm = ComponentViewModel()
        
        let existingComponent = MealComponent(
            name: "Nasi",
            portionPercentage: 50
        )
        
        let targetComponent = MealComponent(
            name: "Ayam Goreng",
            portionPercentage: 50
        )

        vm.components = [
            existingComponent,
            targetComponent
        ]

        vm.updateName(for: targetComponent.id, to: "Nasi")

        #expect(vm.components[1].name == "Ayam Goreng")
    }

    @Test("Meal Name: Validasi gagal jika nama menu kosong bersih")
    func testEmptyMealNameValidation() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi Putih",
                portionPercentage: 100
            )
        ]

        vm.mealName = ""

        #expect(vm.isDishValid == false)
    }

    @Test(
        "Meal Name: Validasi gagal jika nama menu hanya berisi spasi/whitespaces"
    )
    func testWhitespaceMealNameValidation() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi Putih",
                portionPercentage: 100
            )
        ]

        vm.mealName = "      "

        #expect(vm.isDishValid == false)
    }

    @Test(
        "Meal Name: Validasi berhasil jika nama menu terisi dan total porsi pas 100%"
    )
    func testValidMealNameAndProportion() {
        let vm = ComponentViewModel()
        vm.mealName = "Nasi Ayam Panggang"
        vm.components = [
            MealComponent(
                name: "Nasi Putih",
                portionPercentage: 60
            ),
            MealComponent(
                name: "Ayam Panggang",
                portionPercentage: 40
            ),
        ]

        #expect(vm.isDishValid == true)
    }
}
