//
//  ComponentModificationView.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 14/07/26.
//

import SwiftUI

struct ComponentModificationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ComponentViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - SECTION 1: NAMA MENU (EDITABLE)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Nama Menu")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .padding(.top)
                    }

                    VStack {
                        HStack {
                            TextField(
                                "Masukkan nama menu",
                                text: $viewModel.mealName
                            )
                            .font(.body)
                            .frame(minHeight: 40)
                            .fontWeight(.regular)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.textBorder), lineWidth: 2)
                    )
                    .padding(.horizontal)
                }
                .onTapGesture {
                    hideKeyboard()
                }

                // MARK: - SECTION 2: KOMPONEN TERDETEKSI

                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Komponen Terdeteksi")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(.top)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.max")
                            .font(.title3)
                            .foregroundColor(.accent)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pastikan komponen sudah sesuai")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.accent)
                            Text(
                                "Komponen yang tepat akan membantu kami memberikan evaluasi gizi yang akurat."
                            )
                            .font(.caption)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.dryPistachio)
                    .cornerRadius(12)
                    .padding(.bottom)

                    HStack(spacing: 4) {
                        Text("Sisa komposisi yang harus ditambahkan:")
                            .font(.callout)
                            .foregroundColor(.black)
                            .fontWeight(.medium)
                        Text("\(viewModel.remainingPercentage)%")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(
                                viewModel.remainingPercentage == 0
                                    ? .green : .red
                            )
                    }
                    .padding(.bottom, 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // MARK: - EDITABLE LIST
                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.components.indices, id: \.self) {
                            index in
                            HStack(spacing: 12) {
                                TextField(
                                    "Nama Komponen",
                                    text: Binding(
                                        get: {
                                            viewModel.components[index].name
                                        },
                                        set: {
                                            viewModel.updateName(
                                                for: viewModel.components[index]
                                                    .id,
                                                to: $0
                                            )
                                        }
                                    )
                                )
                                .font(.body)
                                .fontWeight(.regular)
                                .frame(minHeight: 44)

                                Spacer()

                                TextField(
                                    "",
                                    value: proportionBinding(for: index),
                                    format: .number
                                )
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.body)
                                .frame(width: 50, height: 44)
                                .background(Color.background)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            Color(.textBorder),
                                            lineWidth: 1.5
                                        )
                                )

                                Text("%")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 2)
                            .cornerRadius(16)
                            .id(viewModel.components[index].id)
                            .listRowSeparator(.visible)
                            .alignmentGuide(.listRowSeparatorLeading) { d in
                                d[.leading]
                            }

                        }
                        .onDelete { indexSet in
                            withAnimation(
                                .spring(response: 0.3, dampingFraction: 0.7)
                            ) {
                                viewModel.removeComponent(at: indexSet)
                            }
                        }

                        // MARK: - Button Tambah
                        VStack {
                            Button(action: {
                                viewModel.addComponent(
                                    category: .protein,
                                    portionPercentage: 1
                                )
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Tambah Komponen")
                                }
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(
                                    viewModel.remainingPercentage <= 0
                                        ? .gray : .black
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    viewModel.remainingPercentage <= 0
                                        ? Color(.systemGray6)
                                        : Color(.buttonTambah)
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Color.textBorder,
                                            style: StrokeStyle(
                                                lineWidth: 2,
                                                dash: [4]
                                            )
                                        )
                                )
                            }
                            .disabled(viewModel.remainingPercentage <= 0)
                        }
                        .listRowSeparator(.hidden)
                        .buttonStyle(.plain)

                        HStack {
                            Text(
                                "Total komposisi wajib 100%. Kurangi persentase salah satu komponen untuk menambahkan komponen baru."
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                            .lineSpacing(0)

                            Spacer()
                        }
                        .padding(.vertical, 10)

                        Color.clear
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .id("BOTTOM_ANCHOR")
                    }
                    .listRowSeparator(.hidden)
                    .onChange(of: viewModel.components.count) {
                        oldCount,
                        newCount in
                        guard oldCount > 0 else { return }
                        if newCount > oldCount {
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.1
                            ) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(
                                        "BOTTOM_ANCHOR",
                                        anchor: .bottom
                                    )
                                }
                            }
                        }
                    }

                }
                .listStyle(.inset)
                .background(Color.clear)
                .scrollDismissesKeyboard(.interactively)

            }
            .onAppear {
                viewModel.components = [
                    MealComponent(
                        name: "Nasi Putih",
                        category: .stapleFood,
                        portionPercentage: 30
                    ),
                    MealComponent(
                        name: "Ayam Panggang",
                        category: .protein,
                        portionPercentage: 20
                    ),
                    MealComponent(
                        name: "Tomat",
                        category: .vegetable,
                        portionPercentage: 10
                    ),
                    MealComponent(
                        name: "Alpukat",
                        category: .fruit,
                        portionPercentage: 6
                    ),
                ]
            }
            .navigationTitle("Komponen Makanan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {

                        // TODO: update submit untuk evaluasi
                        let newEvaluation = MealEvaluation(
                            mealName: viewModel.mealName.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ),
                            components: viewModel.components,
                            categoryEvaluations: [],
                            overallStatus: .needsImprovement,
                            summary: ""
                        )
                        print(
                            "Memicu kalkulasi gizi untuk menu: \(newEvaluation.mealName)"
                        )
                    } label: {
                        Image(systemName: "checkmark")
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isDishValid)
                }
            }
        }
    }
}

extension ComponentModificationView {
    private func proportionBinding(for index: Int) -> Binding<Int> {
        Binding(
            get: {
                guard index < viewModel.components.count else { return 0 }
                return viewModel.components[index].portionPercentage
            },
            set: { newValue in
                guard index < viewModel.components.count else { return }
                viewModel.updateProportion(
                    for: viewModel.components[index].name,
                    to: newValue
                )
            }
        )
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    ComponentModificationView()
}
