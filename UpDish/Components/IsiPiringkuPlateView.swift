//
//  IsiPiringkuPlateView.swift
//  UpDish
//
//  The colour-coded plate visual. Each Isi Piringku group is a wedge sized
//  by its recommended proportion; present groups are green, missing groups
//  are highlighted pink. Built from a custom SwiftUI Shape.
//

import SwiftUI
import UIKit

/// A pie wedge between two angles.
struct PlateWedge: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct IsiPiringkuPlateView: View {
    let evaluations: [CategoryEvaluation]
    var diameter: CGFloat = 150

    /// Deterministic asset name that encodes each group's status, in the fixed
    /// order karbo → lauk → sayur → buah. Example:
    /// `piring_karbo-cukup_lauk-cukup_sayur-kurang_buah-kosong`.
    /// Add illustrated plates to the asset catalog under these names; any combo
    /// without an asset falls back to the drawn plate below.
    static func assetName(for evaluations: [CategoryEvaluation]) -> String {
        let tokens = FoodCategory.plateOrder.map { category -> String in
            let status = evaluations.first { $0.category == category }?.status ?? .missing
            return "\(category.assetSlug)-\(status.assetToken)"
        }
        return "piring_" + tokens.joined(separator: "_")
    }

    /// Precomputed wedge geometry, laid out clockwise from the top so fruit &
    /// protein form the small top wedges and staple & vegetables the large
    /// bottom ones.
    private var wedges: [(evaluation: CategoryEvaluation, start: Angle, end: Angle, mid: Angle)] {
        var result: [(CategoryEvaluation, Angle, Angle, Angle)] = []
        var cursor = -90.0 // start at the top
        for category in FoodCategory.plateSequence {
            guard let evaluation = evaluations.first(where: { $0.category == category }) else { continue }
            let sweep = category.plateProportion * 360
            let start = cursor
            let end = cursor + sweep
            result.append((
                evaluation,
                .degrees(start),
                .degrees(end),
                .degrees(start + sweep / 2)
            ))
            cursor = end
        }
        return result
    }

    var body: some View {
        Group {
            if let image = UIImage(named: Self.assetName(for: evaluations)) {
                // Illustrated plate for this exact combination of statuses.
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // No matching asset yet — fall back to the drawn plate.
                drawnPlate
            }
        }
        .frame(width: diameter, height: diameter)
        // Decorative: the checklist next to it already states every group's
        // status, so announcing the plate too would just repeat it.
        .accessibilityHidden(true)
    }

    /// The programmatic wedge plate, used whenever an illustrated asset for the
    /// current status combination hasn't been added to the catalog.
    private var drawnPlate: some View {
        ZStack {
            ForEach(wedges, id: \.evaluation.id) { wedge in
                PlateWedge(startAngle: wedge.start, endAngle: wedge.end)
                    .fill(wedge.evaluation.status.plateFill)
                PlateWedge(startAngle: wedge.start, endAngle: wedge.end)
                    .stroke(Color.black, lineWidth: 1.5)

                emoji(for: wedge)
            }
            Circle()
                .stroke(Color.black, lineWidth: 1.5)
        }
    }

    private func emoji(for wedge: (evaluation: CategoryEvaluation, start: Angle, end: Angle, mid: Angle)) -> some View {
        let radius = diameter * 0.28
        let x = cos(wedge.mid.radians) * radius
        let y = sin(wedge.mid.radians) * radius
        return Text(wedge.evaluation.category.emoji)
            .font(.system(size: diameter * 0.16))
            .offset(x: x, y: y)
    }
}

#Preview {
    IsiPiringkuPlateView(
        evaluations: [
            CategoryEvaluation(category: .stapleFood, portionPercentage: 34, status: .sufficient, targetPercentage: FoodCategory.stapleFood.targetPercentage),
            CategoryEvaluation(category: .protein, portionPercentage: 16, status: .sufficient, targetPercentage: FoodCategory.protein.targetPercentage),
            CategoryEvaluation(category: .vegetable, portionPercentage: 34, status: .sufficient, targetPercentage: FoodCategory.vegetable.targetPercentage),
            CategoryEvaluation(category: .fruit, portionPercentage: 0, status: .missing, targetPercentage: FoodCategory.fruit.targetPercentage)
        ]
    )
    .padding()
}
