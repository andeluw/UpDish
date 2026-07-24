//
//  IsiPiringkuGuideView.swift
//  UpDish
//
//  Created by Andra Rachmantara on 15/07/26.
//

import SwiftUI

// SwiftUI implementation of the revised "Panduan Isi Piringku" hi-fi.
// The default plate artwork is loaded from Assets.xcassets using the name `Piringku`.
struct IsiPiringkuGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let plateImage: Image?

    private let pageBackground = Color(red: 0.995, green: 0.99, blue: 0.975)
    private let proteinColor = Color(red: 0.95, green: 0.42, blue: 0.44)
    private let stapleColor = Color(red: 0.95, green: 0.64, blue: 0.12)
    private let vegetableColor = Color(red: 0.43, green: 0.66, blue: 0.29)
    private let connectorColor = Color.black
    private let cardBorderColor = Color(red: 0.89, green: 0.86, blue: 0.80)
    private let portionBackground = Color(red: 0.91, green: 0.88, blue: 0.82)
    private let tableHorizontalPadding: CGFloat = 18
    private let tableFirstColumnWidth: CGFloat = 108

    // Loads the `Piringku` asset by default while still allowing a custom image or nil for testing.
    init(plateImage: Image? = Image("Piringku")) {
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
                    header

                    plateGuide
                        .padding(.top, usesExpandedLayout ? 26 : 30)

                    principleSection
                        .padding(.top, usesExpandedLayout ? 30 : 22)
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(pageBackground.ignoresSafeArea())
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

    // MARK: - Header

    // Builds an adaptive header for standard and Accessibility text sizes.
    @ViewBuilder
    private var header: some View {
        if usesExpandedLayout {
            VStack(alignment: .leading, spacing: 16) {
                Text("Panduan Isi Piringku")
                    .font(.title.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
        } else {
            ZStack {
                Text("Panduan Isi Piringku")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 64)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
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

    // Creates the hi-fi diagram with labels and connector lines for standard text sizes.
    private var standardPlateGuide: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let centerX = width / 2
            let plateSize = min(width * 0.58, 228)

            ZStack {
                plateArtwork
                    .frame(width: plateSize, height: plateSize)
                    .position(x: centerX, y: 148)

                connector(
                    from: CGPoint(x: centerX - plateSize * 0.48, y: 88),
                    to: CGPoint(x: centerX - plateSize * 0.31, y: 104),
                    color: connectorColor
                )

                connector(
                    from: CGPoint(x: centerX + plateSize * 0.48, y: 90),
                    to: CGPoint(x: centerX + plateSize * 0.31, y: 106),
                    color: connectorColor
                )

                connector(
                    from: CGPoint(x: centerX - plateSize * 0.48, y: 215),
                    to: CGPoint(x: centerX - plateSize * 0.30, y: 202),
                    color: connectorColor
                )

                connector(
                    from: CGPoint(x: centerX + plateSize * 0.48, y: 218),
                    to: CGPoint(x: centerX + plateSize * 0.31, y: 205),
                    color: connectorColor
                )

                diagramLabel("Lauk-pauk", alignment: .leading)
                    .position(x: 70, y: 60)

                diagramLabel("Buah-\nbuahan", alignment: .leading)
                    .position(x: width - 30, y: 60)

                diagramLabel("Makanan Pokok", alignment: .leading)
                    .position(x: 74, y: 245)

                diagramLabel("Sayuran", alignment: .leading)
                    .position(x: width - 45, y: 240)
            }
        }
        .frame(height: 280)
        .padding(.horizontal, 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Diagram Isi Piringku terdiri dari makanan pokok, lauk-pauk, sayuran, dan buah-buahan"
        )
    }

    // Creates a vertical plate layout that prevents collisions at large text sizes.
    private var accessiblePlateGuide: some View {
        VStack(alignment: .leading, spacing: 24) {
            plateArtwork
                .frame(maxWidth: 260)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 16) {
                accessibleCategoryLabel("Lauk-pauk", color: proteinColor)
                accessibleCategoryLabel("Buah-buahan", color: proteinColor)
                accessibleCategoryLabel("Makanan Pokok", color: stapleColor)
                accessibleCategoryLabel("Sayuran", color: vegetableColor)
            }
        }
        .padding(.horizontal, 24)
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

    // Creates a text label positioned around the standard plate diagram.
    private func diagramLabel(
        _ text: String,
        alignment: TextAlignment
    ) -> some View {
        Text(text)
            .font(.callout.bold())
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: 104, alignment: .leading)
    }

    // Creates a colored category row for the expanded Accessibility layout.
    private func accessibleCategoryLabel(_ text: String, color: Color) -> some View {
        Label {
            Text(text)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.black)
                .accessibilityHidden(true)
        }
    }

    // Draws a black connector line and endpoint between a label and the plate.
    private func connector(
        from start: CGPoint,
        to end: CGPoint,
        color: Color
    ) -> some View {
        ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .position(start)
        }
        .accessibilityHidden(true)
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
            // IsiPiringkuGuideView automatically loads Image("Piringku") from Assets.xcassets.
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
