//
//  UpDishApp.swift
//  UpDish
//
//  Created by Andrew Wallace on 10/07/26.
//

import SwiftData
import SwiftUI
import SwiftData

@main
struct UpDishApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.light)
        }
        .modelContainer(for: MealHistoryRecord.self)
    }
}
