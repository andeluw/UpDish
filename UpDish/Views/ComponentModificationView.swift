//
//  ComponentModificationView.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 14/07/26.
//

import SwiftData
import SwiftUI

struct ComponentModificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ComponentViewModel

    init(draft: MealDraft) {
        _viewModel = StateObject(
            wrappedValue: ComponentViewModel(draft: draft)
        )
    }

    private let recommendationService = RecommendationService()

    /// Set once the user confirms — drives navigation to the result screen and
    /// doubles as the "already confirmed" guard against repeated submits.
    @State private var confirmedEvaluation: MealEvaluation?

    /// True while components are being classified and evaluated.
    @State private var isConfirming = false

    /// Dynamic untuk larger text
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var buttonLabelLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    // MARK: - SECTION 1: NAMA MENU (EDITABLE)
                    VStack(alignment: .leading) {
                        Text("Nama Menu")
                            .font(.headline)
                            .fontWeight(.bold)

                        HStack {
                            TextField(
                                "Masukkan nama menu",
                                text: $viewModel.mealName,
                                axis: .vertical
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1...4)
                            .frame(minHeight: 48)
                        }
                        .padding(.horizontal)
                        .frame(minHeight: 48)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.textBorder), lineWidth: 2)
                        )
                    }
                    .onTapGesture { hideKeyboard() }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(
                        EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
                    )

                    // MARK: - SECTION 2: KOMPONEN TERDETEKSI
                    VStack(alignment: .leading) {
                        Text("Komponen Terdeteksi")
                            .font(.headline)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top)

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lightbulb.max")
                                .font(.title3)
                                .foregroundColor(.black)
                                .accessibilityHidden(true)
                                .fixedSize()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pastikan komponen sudah sesuai")
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )

                                Text(
                                    "Komponen yang tepat akan membantu kami memberikan evaluasi gizi yang akurat."
                                )
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 68,
                            alignment: .leading
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.textBorder), lineWidth: 2)
                        )
                        .background(Color.buttonTambah)
                        .cornerRadius(10)
                        .padding(.bottom)
                        .accessibilityElement(children: .combine)

                        HStack(spacing: 4) {
                            Text("Sisa komposisi yang harus ditambahkan:")
                                .font(.caption)
                                .foregroundColor(.black)
                                .fontWeight(.medium)

                            Text("\(viewModel.remainingPercentage)%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(
                                    viewModel.remainingPercentage == 0
                                        ? .green : .red
                                )
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 5)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "Sisa komposisi yang harus ditambahkan adalah \(viewModel.remainingPercentage) persen"
                        )
                        
                        HStack{
                            Text("Setiap komponen harus memiliki persentase minimal 1%.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture { hideKeyboard() }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(
                        EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
                    )

                    // MARK: - EDITABLE LIST
                    ForEach(viewModel.components.indices, id: \.self) { index in
                        let component = viewModel.components[index]
                        ComponentRowView(
                            component: component,
                            onNameChange: {
                                viewModel.updateName(for: component.id, to: $0)
                            },
                            onProportionChange: {
                                viewModel.updateProportion(
                                    for: component.id,
                                    to: $0
                                )
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(
                            EdgeInsets(
                                top: 8,
                                leading: 16,
                                bottom: 6,
                                trailing: 16
                            )
                        )
                        .id(component.id)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.removeComponent(
                                        at: IndexSet(integer: index)
                                    )
                                }
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                            .buttonBorderShape(.roundedRectangle(radius: 1))
                            .accessibilityLabel("Hapus")
                        }
                    }

                    // MARK: - Button Tambah
                    VStack {
                        Button(action: {
                            viewModel.addComponent(portionPercentage: 1)
                        }) {
                            buttonLabelLayout {
                                Image(systemName: "plus")
                                Text("Tambah Komponen")
                                    .multilineTextAlignment(.center)
                            }
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.remainingPercentage <= 0 ? .accent.opacity(0.43) : .accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 10 : 0)
                            .frame(minHeight: 54)
                            .background(Color(.buttonTambah))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.remainingPercentage <= 0 ? .accent.opacity(0.43) : .accent, style: StrokeStyle(lineWidth: 2, dash: [4]))
                            )
                        }
                        .disabled(viewModel.remainingPercentage <= 0)

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
                    }
                    .listRowSeparator(.hidden)
                    .id("BOTTOM_ANCHOR")
                }
                .listStyle(.inset)
                .background(Color.clear)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.components.count) {
                    oldCount,
                    newCount in
                    guard oldCount > 0 else { return }
                    if newCount > oldCount {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("BOTTOM_ANCHOR", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
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
                        Task { await confirm() }
                    } label: {
                        if isConfirming {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                                .bold()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    // Disabled while the list is invalid, while confirming, and
                    // once confirmed — preventing a repeated confirmation.
                    .disabled(
                        !viewModel.isDishValid
                            || confirmedEvaluation != nil
                            || isConfirming
                    )
                }
            }
            .navigationDestination(item: $confirmedEvaluation) { evaluation in
                EvaluationResultView(
                    viewModel: EvaluationResultViewModel(
                        evaluation: evaluation,
                        modelContext: modelContext
                    )
                )
            }
        }
    }

    /// Runs the real Isi Piringku evaluation on the corrected components,
    /// saves it to history (food name + components + recommendation), and
    /// navigates to the result screen (where the Foundation Model pipeline runs
    /// automatically). Guarded so a double-tap can't confirm twice.
    private func confirm() async {
        guard confirmedEvaluation == nil, !isConfirming else { return }

        isConfirming = true
        defer { isConfirming = false }

        // Classifies the detected components into Isi Piringku groups first,
        // otherwise nothing would count toward the plate.
        let evaluation = await viewModel.makeEvaluation()
        persist(evaluation)
        confirmedEvaluation = evaluation
    }

    /// Stores the analyzed meal so it appears in the Home history. The
    /// recommendation saved here is the deterministic one; the result screen
    /// still shows the Foundation Model's version live.
    private func persist(_ evaluation: MealEvaluation) {
        let result = MealResult(
            evaluation: evaluation,
            recommendation: recommendationService.recommendation(
                for: evaluation
            )
        )
        modelContext.insert(MealHistoryRecord(result: result))
        try? modelContext.save()
    }
}

struct ComponentRowView: View {
    let component: MealComponent
    let onNameChange: (String) -> Void
    let onProportionChange: (Int) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var dynamicLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { component.name },
            set: onNameChange
        )
    }

    private var portionBinding: Binding<Int> {
        Binding(
            get: { component.portionPercentage },
            set: onProportionChange
        )
    }

    var body: some View {
        dynamicLayout {
            nameField

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }

            portionField
        }
        .padding(.horizontal, 14)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 12 : 0)
        .frame(minHeight: 54)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.textBorder), lineWidth: 2)
        )
    }

    private var nameField: some View {
        TextField("Masukkan nama komponen", text: nameBinding)
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(minHeight: 40)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
            .layoutPriority(1)
            .accessibilityLabel("Nama komponen")
            .accessibilityValue(component.name.isEmpty ? "kosong" : component.name)
    }

    private var portionField: some View {
        HStack(spacing: 4) {
            TextField("", value: portionBinding, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(minWidth: 41, minHeight: 30)
                .padding(.horizontal, 6)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.textBorder), lineWidth: 2)
                )
                .accessibilityLabel("Persentase porsi")
                .accessibilityValue("\(component.portionPercentage) persen")

            Text("%")
                .font(.body)
                .foregroundColor(.black)
                .accessibilityHidden(true)
        }
        .fixedSize(horizontal: true, vertical: false)
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
    ComponentModificationView(
        draft: MealDraft(
            mealName: "Nasi Ayam Sayur mantap gas",
            components: [
                MealComponent(
                    name: "Nasi Putih",
                    portionPercentage: 50
                ),
                MealComponent(
                    name: "Ayam Goreng",
                    portionPercentage: 25
                ),
                MealComponent(
                    name: "Tumis Sayur",
                    portionPercentage: 25
                ),
            ]
        )
    )
    .modelContainer(for: MealHistoryRecord.self, inMemory: true)
}
