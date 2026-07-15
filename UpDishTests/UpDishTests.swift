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
                category: .stapleFood,
                portionPercentage: 40
            ),
            MealComponent(
                name: "Ayam Goreng",
                category: .protein,
                portionPercentage: 30
            ),
            MealComponent(
                name: "Telur",
                category: .protein,
                portionPercentage: 30
            ),
        ]

        vm.removeComponent(at: IndexSet(integer: 2))

        #expect(vm.components.count == 2)
        #expect(vm.components[0].name == "Nasi")
        #expect(vm.components[1].name == "Ayam Goreng")
        #expect(!vm.components.contains(where: { $0.name == "Telur" }))
    }

    @Test("Add: Menambah komponen baru dengan nama default otomatis")
    func testAddComponent() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                category: .stapleFood,
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam Goreng",
                category: .protein,
                portionPercentage: 49
            ),
        ]

        vm.addComponent(category: .vegetable, portionPercentage: 1)

        #expect(vm.components.count == 3)
        #expect(vm.components.last?.name == "Komponen Baru 1")
    }

    @Test(
        "Collision: Otomatis menaikkan indeks nama jika 'Komponen Baru 1' sudah ada"
    )
    func testAutoResolveNamingCollision() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Komponen Baru 1",
                category: .protein,
                portionPercentage: 10
            )
        ]
        vm.addComponent(category: .vegetable, portionPercentage: 5)
        #expect(vm.components.count == 2)
        #expect(vm.components.last?.name == "Komponen Baru 2")
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
                category: .stapleFood,
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam",
                category: .protein,
                portionPercentage: 50
            ),
        ]

        vm.updateProportion(for: "Nasi", to: 30)
        vm.updateProportion(for: "Ayam", to: 20)
        vm.addComponent(category: .vegetable, portionPercentage: 50)

        #expect(vm.isDishValid == true)
    }

    @Test("Underflow: Validasi gagal jika total kurang dari 100%")
    func testUnderflowProportion() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                category: .stapleFood,
                portionPercentage: 30
            ),
            MealComponent(
                name: "Ayam",
                category: .protein,
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
                category: .stapleFood,
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam",
                category: .protein,
                portionPercentage: 30
            ),
            MealComponent(
                name: "Bayam",
                category: .vegetable,
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
                category: .stapleFood,
                portionPercentage: 40
            ),
            MealComponent(
                name: "Ayam",
                category: .protein,
                portionPercentage: 30
            ),
            MealComponent(
                name: "Telur",
                category: .protein,
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
                category: .stapleFood,
                portionPercentage: 50
            ),
            MealComponent(
                name: "Ayam",
                category: .protein,
                portionPercentage: 50
            ),
        ]

        vm.updateProportion(for: "Ayam", to: -20)

        #expect(vm.components[1].portionPercentage >= 0)
    }

    @Test("Huge Value: Memotong nilai yang lebih dari 100% menjadi tepat 100%")
    func testHugeProportionCapping() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi",
                category: .stapleFood,
                portionPercentage: 50
            )
        ]

        vm.updateProportion(for: "Nasi", to: 120)

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
                category: .stapleFood,
                portionPercentage: 99
            ),
            MealComponent(
                name: "Ayam",
                category: .protein,
                portionPercentage: 1
            ),
        ]

        vm.updateProportion(for: "Ayam", to: 0)

        #expect(vm.components[1].portionPercentage == 1)
    }

    @Test("Edit Name: Mengubah nama komponen yang sudah ada")
    func testEditComponentName() {
        let vm = ComponentViewModel()
        let componentID = UUID()

        vm.components = [
            MealComponent(
                id: componentID,
                name: "Ayam Goreng",
                category: .protein,
                portionPercentage: 50
            )
        ]

        vm.updateName(for: componentID, to: "Ayam Bakar")

        #expect(vm.components[0].name == "Ayam Bakar")
        #expect(vm.components[0].portionPercentage == 50)
    }

    @Test(
        "Edit Name Duplicate: Menolak perubahan nama jika nama baru sudah ada di piring"
    )
    func testEditComponentNameDuplicate() {
        let vm = ComponentViewModel()
        let targetID = UUID()

        vm.components = [
            MealComponent(
                name: "Nasi",
                category: .stapleFood,
                portionPercentage: 50
            ),
            MealComponent(
                id: targetID,
                name: "Ayam Goreng",
                category: .protein,
                portionPercentage: 50
            ),
        ]

        vm.updateName(for: targetID, to: "Nasi")

        #expect(vm.components[1].name == "Ayam Goreng")
    }

    @Test("Meal Name: Validasi gagal jika nama menu kosong bersih")
    func testEmptyMealNameValidation() {
        let vm = ComponentViewModel()
        vm.components = [
            MealComponent(
                name: "Nasi Putih",
                category: .stapleFood,
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
                category: .stapleFood,
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
                category: .stapleFood,
                portionPercentage: 60
            ),
            MealComponent(
                name: "Ayam Panggang",
                category: .protein,
                portionPercentage: 40
            ),
        ]

        #expect(vm.isDishValid == true)
    }
}
