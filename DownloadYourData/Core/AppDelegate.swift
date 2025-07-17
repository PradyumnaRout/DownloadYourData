//
//  AppDelegate.swift
//  DownloadYourData
//
//  Created on 17/07/25.
//

import Foundation
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        MyDownloadManager.shared.resumePersistedDownloads()
        MyDownloadManager.shared.resumeAllRunningTasks()
        
        return true
    }
    
    //only called if the app is terminated or suspended
    func application(_: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        MyDownloadManager.shared.storeCompletionHandler(identifier, completionHandler)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        MyDownloadManager.shared.pauseAllRunningTasks()
        MyDownloadManager.shared.persistInProgressTasks()
    }
}

