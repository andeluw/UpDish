//
//  UpDishApp.swift
//  UpDish
//
//  Created by Andrew Wallace on 10/07/26.
//

import SwiftUI

@main
struct UpDishApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
        }
    }
}
