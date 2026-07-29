//
//  AppleIntelligenceNotice.swift
//  UpDish
//
//  Passive Home banner telling the user Apple Intelligence is off or still
//  preparing. Its copy comes from AppleIntelligenceStatus. This is the only
//  place we surface the state now — the onboarding and pre-feedback alerts
//  were removed, because the banner text already explains where to enable it.
//

import SwiftUI

/// Informational strip shown above the Home content. Not interactive: the text
/// itself names the Settings path, so there is nothing to tap.
struct AppleIntelligenceBanner: View {
    let status: AppleIntelligenceStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.noticeIcon)
                .font(.callout)
                .foregroundStyle(Self.foreground)
                .accessibilityHidden(true)

            Text(status.noticeText)
                .font(.footnote)
                .foregroundStyle(Self.foreground)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Self.border, lineWidth: 1.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.noticeText)
    }

    private static let foreground = Color.black                                              // #000000
    private static let border = Color(red: 232 / 255, green: 224 / 255, blue: 211 / 255)     // #E8E0D3
    private static let background = Color(red: 245 / 255, green: 242 / 255, blue: 236 / 255)  // #F5F2EC
}

#Preview("Belum aktif") {
    AppleIntelligenceBanner(status: .notEnabled)
        .padding()
}

#Preview("Sedang disiapkan") {
    AppleIntelligenceBanner(status: .preparing)
        .padding()
}
