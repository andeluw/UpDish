import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false

    var body: some View {

        VStack {

            Spacer()

            Image("onboardingplate")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 242)
                .padding(.bottom, 13)

            VStack(spacing: 12) {

                Text("Evaluasi Gizi\nPiringmu")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 62/255,
                                           green: 79/255,
                                           blue: 34/255))
                    .multilineTextAlignment(.center)

                Text("Kami akan mengevaluasi komposisi makananmu dan memberikan saran agar lebih seimbang.")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

            }

            Spacer()

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
                        Color(red: 64/255,
                              green: 76/255,
                              blue: 36/255)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))

            }
            .padding(.horizontal, 70)
            .padding(.bottom, 96)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(red: 254/255, green: 252/255, blue: 249/255)
        )
    }
}

#Preview {
    OnboardingView()
}
