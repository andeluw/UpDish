//
//  IsiPiringkuGuideView.swift
//  UpDish
//
//  Created by Andra Rachmantara on 15/07/26.
//

import SwiftUI

// SwiftUI implementation of the revised "Panduan Isi Piringku" hi-fi.
// The default guide artwork is loaded from Assets.xcassets using the name `IsiPiringkuGuide`.
struct IsiPiringkuGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let plateImage: Image?

    private let pageBackground = Color(red: 0.995, green: 0.99, blue: 0.975)
    private let vegetableColor = Color(red: 0.43, green: 0.66, blue: 0.29)
    private let cardBorderColor = Color(red: 0.89, green: 0.86, blue: 0.80)
    private let portionBackground = Color(red: 0.91, green: 0.88, blue: 0.82)
    private let tableHorizontalPadding: CGFloat = 18
    private let tableFirstColumnWidth: CGFloat = 108

    // Loads the full `IsiPiringkuGuide` asset by default while still allowing a custom image or nil for testing.
    init(plateImage: Image? = Image("IsiPiringkuGuide")) {
        self.plateImage = plateImage
    }

    // Returns true when the text size needs the expanded, collision-free layout.
    private var usesExpandedLayout: Bool {
        dynamicTypeSize >= .xxxLarge
    }

    // Builds the complete scrollable guide screen.
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    plateGuide
                        .padding(.top, usesExpandedLayout ? 18 : 22)

                    principleSection
                        .padding(.top, usesExpandedLayout ? 44 : 34)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle("Panduan Isi Piringku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup", systemImage: "xmark", action: dismiss.callAsFunction)
                        .labelStyle(.iconOnly)
                }
            }
            // Supports the VoiceOver two-finger Z gesture to close this guide.
            .accessibilityAction(.escape) {
                dismiss()
            }
        }
    }

    // MARK: - Plate guide

    // Selects the appropriate plate layout for the current Dynamic Type size.
    @ViewBuilder
    private var plateGuide: some View {
        if usesExpandedLayout {
            accessiblePlateGuide
        } else {
            standardPlateGuide
        }
    }

    // Shows the complete guide artwork as one scalable image.
    private var standardPlateGuide: some View {
        labeledPlateArtwork(maxWidth: 270)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Layout Isi Piringku terdiri dari makanan pokok, lauk-pauk, sayuran, dan buah-buahan"
            )
    }

    // Shows the complete guide artwork at a smaller scale for Accessibility text sizes.
    private var accessiblePlateGuide: some View {
        labeledPlateArtwork(maxWidth: 260)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Layout Isi Piringku terdiri dari makanan pokok, lauk-pauk, sayuran, dan buah-buahan"
            )
    }

    // Adds fixed guide labels over the existing guide artwork without changing the image asset.
    private func labeledPlateArtwork(maxWidth: CGFloat) -> some View {
        Color.clear
            .aspectRatio(634.0 / 484.0, contentMode: .fit)
            .frame(maxWidth: maxWidth)
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height

                    ZStack {
                        plateArtwork
                            .frame(width: width, height: height)

                        guideLabel("Lauk-pauk")
                            .position(x: width * 0.04, y: height * 0.05)

                        guideLabel("Buah-\nbuahan")
                            .position(x: width * 1.01, y: height * 0.03)

                        guideLabel("Makanan\nPokok")
                            .position(x: width * 0.08, y: height * 0.95)

                        guideLabel("Sayuran")
                            .position(x: width * 1.01, y: height * 0.95)
                    }
                }
            }
    }

    private func guideLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.black)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: 92, alignment: .leading)
    }

    // Displays the supplied plate image or a temporary placeholder.
    @ViewBuilder
    private var plateArtwork: some View {
        if let plateImage {
            plateImage
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Ilustrasi pembagian Isi Piringku")
        } else {
            ZStack {
                Circle()
                    .fill(Color.white)

                Circle()
                    .stroke(Color(red: 0.82, green: 0.73, blue: 0.64), lineWidth: 6)

                Circle()
                    .stroke(Color(red: 0.90, green: 0.84, blue: 0.78), lineWidth: 2)
                    .padding(11)

                VStack(spacing: 10) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(vegetableColor)
                        .accessibilityHidden(true)

                    Text("Ilustrasi akan ditambahkan")
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
            .accessibilityLabel("Ilustrasi Isi Piringku belum ditambahkan")
        }
    }

    // MARK: - Principles

    // Builds the principle title and one grouped container with four information rows.
    private var principleSection: some View {
        VStack(spacing: 16) {
            Text("Prinsip Isi Piringku")
                .font(.callout.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                principleCard(
                    title: "Makanan Pokok",
                    portion: "1/3 piring",
                    spokenPortion: "sepertiga piring",
                    description: "Pilih sumber karbohidrat yang berkualitas, seperti nasi, jagung, umbi, atau sagu."
                )

                principleDivider

                principleCard(
                    title: "Lauk Pauk",
                    portion: "1/6 piring",
                    spokenPortion: "seperenam piring",
                    description: "Pilih lauk sumber protein seperti ikan, ayam, telur, tahu, tempe, atau kacang-kacangan."
                )

                principleDivider

                principleCard(
                    title: "Sayuran",
                    portion: "1/3 piring",
                    spokenPortion: "sepertiga piring",
                    description: "Pilih beragam sayuran dengan warna yang berbeda untuk mendapatkan vitamin dan mineral."
                )

                principleDivider

                principleCard(
                    title: "Buah-buahan",
                    portion: "1/6 piring",
                    spokenPortion: "seperenam piring",
                    description: "Pilih berbagai jenis buah segar sebagai sumber vitamin, mineral, dan serat."
                )
            }
            .padding(.vertical, 6)
            .background(
                Color.white.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1.5)
            }
            .overlay(alignment: .leading) {
                if !usesExpandedLayout {
                    Rectangle()
                        .fill(cardBorderColor)
                        .frame(width: 2)
                        .padding(.vertical, 12)
                        .offset(x: tableHorizontalPadding + tableFirstColumnWidth)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, usesExpandedLayout ? 20 : 28)
        .padding(.vertical, 4)
    }

    // Draws a straight separator without adding a border around each row.
    private var principleDivider: some View {
        Rectangle()
            .fill(cardBorderColor)
            .frame(height: 1)
            .padding(.horizontal, tableHorizontalPadding)
            .accessibilityHidden(true)
    }

    // Creates one adaptive row and provides a natural Indonesian VoiceOver pronunciation.
    @ViewBuilder
    private func principleCard(
        title: String,
        portion: String,
        spokenPortion: String,
        description: String
    ) -> some View {
        Group {
            if usesExpandedLayout {
                VStack(alignment: .leading, spacing: 18) {
                    cardIdentity(title: title, portion: portion)

                    Divider()
                        .overlay(cardBorderColor)

                    cardDescription(description)
                }
            } else {
                HStack(alignment: .center, spacing: 0) {
                    cardIdentity(title: title, portion: portion)
                        .frame(width: tableFirstColumnWidth, alignment: .leading)

                    Color.clear
                        .frame(width: 2)

                    cardDescription(description)
                        .padding(.leading, 14)
                }
            }
        }
        .padding(.horizontal, tableHorizontalPadding)
        .padding(.vertical, usesExpandedLayout ? 16 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(spokenPortion). \(description)")
    }

    // Creates the category title and portion badge inside a card.
    private func cardIdentity(
        title: String,
        portion: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(usesExpandedLayout ? .body.weight(.semibold) : .caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text(portion)
                .font(usesExpandedLayout ? .body.bold() : .caption2.bold())
                .foregroundStyle(.black)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(portionBackground, in: Capsule())
                .fixedSize(horizontal: true, vertical: true)
        }
    }

    // Creates the explanatory text shown inside a principle card.
    private func cardDescription(_ description: String) -> some View {
        Text(description)
            .font(usesExpandedLayout ? .body.weight(.medium) : .caption2.weight(.medium))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Example presentation

struct IsiPiringkuGuideButtonExample: View {
    @State private var isGuidePresented = false

    // Demonstrates how to present the guide as an iOS sheet.
    var body: some View {
        Button("Buka Panduan Isi Piringku") {
            isGuidePresented = true
        }
        .sheet(isPresented: $isGuidePresented) {
            // IsiPiringkuGuideView automatically loads Image("IsiPiringkuGuide") from Assets.xcassets.
            IsiPiringkuGuideView()
                .presentationDragIndicator(.visible)
        }
    }
}

struct IsiPiringkuGuideView_Previews: PreviewProvider {
    // Provides previews for default and large Accessibility text sizes.
    static var previews: some View {
        Group {
            IsiPiringkuGuideView()
                .previewDisplayName("Default Text")

            IsiPiringkuGuideView()
                .environment(\.dynamicTypeSize, .accessibility3)
                .previewDisplayName("Accessibility 3")
        }
    }
}
