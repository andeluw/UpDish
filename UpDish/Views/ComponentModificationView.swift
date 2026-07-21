//
//  ComponentModificationView.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 14/07/26.
//

import SwiftUI
import SwiftData

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

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - SECTION 1: NAMA MENU (EDITABLE)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Nama Menu")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top)
                    }

                    HStack {
                        TextField(
                            "Masukkan nama menu",
                            text: $viewModel.mealName
                        )
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    .frame(minHeight: 48)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
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
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.top)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.max")
                            .font(.title3)
                            .foregroundColor(.black)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pastikan komponen sudah sesuai")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            Text(
                                "Komponen yang tepat akan membantu kami memberikan evaluasi gizi yang akurat."
                            )
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
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
                    .padding(.bottom, 5)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Sisa komposisi yang harus ditambahkan adalah \(viewModel.remainingPercentage) persen"
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .onTapGesture {
                    hideKeyboard()
                }

                // MARK: - EDITABLE LIST
                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.components.indices, id: \.self) {
                            index in
                            let component = viewModel.components[index]
                            ComponentRowView(
                                component: component,
                                onNameChange: { viewModel.updateName(for: component.id, to: $0) },
                                onProportionChange: { viewModel.updateProportion(for: component.id, to: $0) }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(top: 8, leading: 16, bottom: 6, trailing: 16)
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
                                    Image(systemName: "trash")
                                        .frame(maxHeight: .infinity)
                                }
                                .buttonBorderShape(.roundedRectangle(radius: 1))
                                .accessibilityLabel("Hapus")
                            }
                        }

                        // MARK: - Button Tambah
                        VStack {
                            Button(action: {
                                viewModel.addComponent(
                                    portionPercentage: 1
                                )
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Tambah Komponen")
                                }
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.remainingPercentage <= 0 ? .accent.opacity(0.43) : .accent)
                                .frame(maxWidth: .infinity, minHeight: 57)
                                .background(Color.buttonTambah)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.remainingPercentage <= 0 ? .accent.opacity(0.43) : .accent,
                                            style: StrokeStyle(
                                                lineWidth: 2,
                                                dash: [5]
                                            )
                                        )
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
            recommendation: recommendationService.recommendation(for: evaluation)
        )
        modelContext.insert(MealHistoryRecord(result: result))
        try? modelContext.save()
    }
}

struct ComponentRowView: View {
    let component: MealComponent
    let onNameChange: (String) -> Void
    let onProportionChange: (Int) -> Void

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
        HStack(spacing: 12) {
            TextField("Nama Komponen", text: nameBinding)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(minHeight: 40)
                .accessibilityLabel("Nama komponen")
                .accessibilityValue(component.name.isEmpty ? "kosong" : component.name)

            Spacer()

            TextField("", value: portionBinding, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 41, height: 30)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            Color(.textBorder),
                            lineWidth: 2
                        )
                )
                .accessibilityLabel("Persentase porsi")
                .accessibilityValue("\(component.portionPercentage) persen")

            Text("%")
                .font(.body)
                .foregroundColor(.black)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 54)
        .padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.textBorder), lineWidth: 2)
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
    ComponentModificationView(
        draft: MealDraft(
            mealName: "Nasi Ayam Sayur",
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
