//
//  IsiPiringkuPlateView.swift
//  UpDish
//
//  The colour-coded plate visual. Each Isi Piringku group is a wedge sized
//  by its recommended proportion; present groups are green, missing groups
//  are highlighted pink. Built from a custom SwiftUI Shape.
//

import SwiftUI

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
        .frame(width: diameter, height: diameter)
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
