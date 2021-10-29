//
//  InzidenzMonitorApp.swift
//  InzidenzMonitor WatchKit Extension
//
//  Created by Markus Ullmann on 29.10.21.
//

import SwiftUI

@main
struct InzidenzMonitorApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
