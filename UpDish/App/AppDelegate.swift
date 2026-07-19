//
//  AppDelegate.swift
//  UpDish
//
//  Created by Andrew Wallace on 19/07/26.
//

import FirebaseAppCheck
import FirebaseCore
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Bundle identifier could not be determined.")
        }
        
        let configurationName: String
        
        switch bundleIdentifier {
        case "com.andeluw.UpDish.dev":
            configurationName = "GoogleService-Info-Dev"
        case "com.andeluw.UpDish":
            configurationName = "GoogleService-Info"
        default:
            fatalError("No Firebase configuration for bundle identifier: \(bundleIdentifier)")
        }
        
        guard
            let filePath = Bundle.main.path(
                forResource: configurationName,
                ofType: "plist"
            ),
            let options = FirebaseOptions(contentsOfFile: filePath)
        else {
            fatalError("\(configurationName).plist was not found in the app bundle.")
        }
        
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(
            AppCheckDebugProviderFactory()
        )
        #else
        AppCheck.setAppCheckProviderFactory(
            AppAttestProviderFactory()
        )
        #endif
        
        FirebaseApp.configure(options: options)
        
        #if DEBUG
        print("Firebase configured using \(configurationName).plist")
        #endif
            
        return true
    }
}
