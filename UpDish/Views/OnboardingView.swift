import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    VStack(spacing: 32) {
                        mainContent
                        actionButton
                    }
                    .padding(.vertical, 32)
                }
            } else {
                VStack(spacing: 0) {
                    Spacer()
                    mainContent
                    Spacer()
                    
                    actionButton
                        .padding(.bottom, 96)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(red: 254/255, green: 252/255, blue: 249/255)
        )
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            Image("onboardingplate")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 242)
                .padding(.bottom, 13)
                .accessibilityElement(children: .ignore)

            VStack(spacing: 12) {
                Text("Evaluasi Gizi\nPiringmu")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 62/255, green: 79/255, blue: 34/255))
                    .multilineTextAlignment(.center)

                Text("Kami menggunakan Apple Intelligence untuk menganalisis komposisi makananmu dan pastikan sudah aktif agar mendapat rekomendasi gizi yang lebih baik.")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 35)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // 🌟 Ekstrak 2: Tombol Mulai
    @ViewBuilder
    private var actionButton: some View {
        Button {
            hasSeenOnboarding = true
        } label: {
            Text("Mulai")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: 262)
                .frame(minHeight: 61)
                .background(
                    Color(red: 64/255, green: 76/255, blue: 36/255)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 70)
    }
}

#Preview {
    OnboardingView()
}
