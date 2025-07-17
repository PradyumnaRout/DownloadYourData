//
//  DownloadYourDataApp.swift
//  DownloadYourData
//
//  Created by hb on 17/07/25.
//

import SwiftUI

@main
struct DownloadYourDataApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            DownloadContentView()
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        print("Become Actice")
//                        DownloadManager.shared.resumeAllRunningTasks()
                    case .background:
                        print("In background")
                    default:
                        break
                    }
                }
        }
    }
}
