//
//  AppleIntelligenceNotice.swift
//  UpDish
//
//  The two ways we surface Apple Intelligence being unavailable: a passive
//  banner (Home) and a native alert (after onboarding, and before generating
//  feedback). Both read their copy from AppleIntelligenceStatus so the three
//  entry points can never drift apart.
//

import SwiftUI

/// Passive strip shown above the Home content. Tappable when there's something
/// to do about it; inert while the model is merely downloading.
struct AppleIntelligenceBanner: View {
    let status: AppleIntelligenceStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: status.noticeIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(Self.accent)
                    .accessibilityHidden(true)

                Text(status.noticeText)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if status.deservesPrompt {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Self.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Self.border, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        // Inert while preparing — there is no switch to flip, so offering a
        // tap target would promise an action that doesn't exist.
        .disabled(!status.deservesPrompt)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.noticeText)
        .accessibilityHint(status.deservesPrompt ? "Ketuk untuk melihat caranya" : "")
    }

    private static let accent = Color(red: 96 / 255, green: 75 / 255, blue: 1 / 255)      // #604B01
    private static let background = Color(red: 254 / 255, green: 245 / 255, blue: 219 / 255) // #FEF5DB
    private static let border = Color(red: 232 / 255, green: 224 / 255, blue: 211 / 255)  // #E8E0D3
}

extension View {
    /// The native alert explaining how to switch Apple Intelligence on.
    ///
    /// Always dismissible: the app produces a full Isi Piringku evaluation
    /// without the model, so this is advice, never a gate. `onDismiss` runs
    /// for both buttons, letting a caller continue whatever it was doing.
    func appleIntelligenceAlert(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        let status = AppleIntelligenceStatus.notEnabled
        return alert(status.alertTitle, isPresented: isPresented) {
            Button("Buka Pengaturan") {
                AppleIntelligenceStatus.openSettings()
                onDismiss?()
            }
            Button("Nanti Saja", role: .cancel) {
                onDismiss?()
            }
        } message: {
            Text(status.alertMessage)
        }
    }
}

#Preview("Belum aktif") {
    AppleIntelligenceBanner(status: .notEnabled) {}
        .padding()
}

#Preview("Sedang disiapkan") {
    AppleIntelligenceBanner(status: .preparing) {}
        .padding()
}
