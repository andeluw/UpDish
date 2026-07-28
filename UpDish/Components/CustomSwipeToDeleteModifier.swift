//
//  CustomSwipeToDeleteModifier.swift
//  UpDish
//
//  Created by Evelin Alim Natadjaja on 27/07/26.
//

import SwiftUI

struct CustomSwipeToDeleteModifier: ViewModifier {
    let action: () -> Void
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: {
                withAnimation {
                    offset = 0
                    action()
                }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(Circle())

                    Text("Hapus")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 16)
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
            .dynamicTypeSize(.large)

            //Card
            content
                .contentShape(Rectangle())
                .background(offset < 0 ? Color(.systemGray6) : Color.white)
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, -100)
                            } else if offset < 0 {
                                offset = min(value.translation.width - 100, 0)
                            }
                        }
                        .onEnded { value in
                            withAnimation(
                                .spring(response: 0.3, dampingFraction: 0.8)
                            ) {
                                if offset < -50 {
                                    offset = -100
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
        }
    }
}

extension View {
    func customSwipeToDelete(action: @escaping () -> Void) -> some View {
        self.modifier(CustomSwipeToDeleteModifier(action: action))
    }
}
