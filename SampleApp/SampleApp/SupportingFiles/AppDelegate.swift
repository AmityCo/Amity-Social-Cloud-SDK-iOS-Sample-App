//
//  AppDelegate.swift
//  SampleApp
//
//  Created by Federico Zanetello on 5/27/19.
//  Copyright © 2019 David Zhang. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Log.add(info: "🛑 Failed to authorize: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        UIScrollView.appearance().keyboardDismissMode = .onDrag
        
        let controller = UIHostingController(rootView: MainContainerView())
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Removes the Push Notification Badge number on the app icon.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: Push Notifications Token Management
    
    func application( _ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts: [String] = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token: String = tokenParts.joined()
        UserDefaults.standard.deviceToken = token
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.add(info: "🛑 Failed to register: \(error.localizedDescription)")
    }
    
    // MARK: UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
