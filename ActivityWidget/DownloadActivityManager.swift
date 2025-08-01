//
//  DownloadActivityManager.swift
//  DownloadYourData
//
//  Created by hb on 01/08/25.
//

import Foundation
import ActivityKit


class DownloadActivityManager {
    
    // Properties
    static let shared = DownloadActivityManager()
    private var activities: [String: Activity<DownloadActivityAttributes>?] = [:]
    
    private init() {}
    
    
    func startActivity(id: String, status: ActivityStatus, fileName: String, progress: Int) {
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attribute = DownloadActivityAttributes(fileName: fileName)
            let initialState = DownloadActivityAttributes.ContentState(downloadStatus: status, progress: progress)
            
            do {
                let actiivity = try Activity<DownloadActivityAttributes>.request(
                    attributes: attribute,
                    content: .init(state: initialState, staleDate: nil)
                )
                
                activities[id] = actiivity
                
            } catch {
                print("Failed to start live acitvity: \(error)")
            }
        }
    }
    
    func updateActivity(id: String, status: ActivityStatus, progress: Int) {
        guard let activity = activities[id] else {
            print("No live activity found for id: \(id)")
            return
        }
        
        let updatedContent = DownloadActivityAttributes.ContentState(downloadStatus: status, progress: progress)
        
        Task {
            await activity?.update(ActivityContent(state: updatedContent, staleDate: nil))
            print("Live activity updated \(progress)")
        }
    }
    
    func endActivity(id: String, status: ActivityStatus, progress: Int) {
        guard let activity = activities[id] else {
            print("No live activity found for id: \(id)")
            return
        }
        
        let endContent = DownloadActivityAttributes.ContentState(downloadStatus: status, progress: progress)
        
        Task {
            await activity?.end(ActivityContent(state: endContent, staleDate: nil), dismissalPolicy: .immediate)
            print("Live activity removed for id: \(id)")
            activities.removeValue(forKey: id) // remove from dictionary
        }
    }
}
