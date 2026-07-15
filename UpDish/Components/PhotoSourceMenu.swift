//
//  PhotoSourceMenu.swift
//  UpDish
//
//  Created by Andrew Wallace on 14/07/26.
//

import SwiftUI

struct PhotoSourceMenu: View {
    let isCameraAvailable: Bool
    let onCamera: () -> Void
    let onPhotoLibrary: () -> Void
    
    var body: some View {
        Menu {
            if isCameraAvailable {
                Button(action: onCamera) {
                    Label("Ambil Foto", systemImage: "camera")
                }
            }
            
            Button(action: onPhotoLibrary) {
                Label("Pilih Foto", systemImage: "photo.on.rectangle")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(Color.accent)
                }
                .contentShape(Circle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Tambah foto")
    }
}
