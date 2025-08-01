//
//  MyDownloadManager.swift
//  DownloadYourData
//
//  Created on 17/07/25.
//

import Foundation


class MyDownloadManager: NSObject, ObservableObject {
    
    static let shared = MyDownloadManager()
    private var urlSession: URLSession!
    
    /// Maps URLSessionDownloadTask taskIdentifier → DownloadItem
    private var taskMap: [Int: DownloadItem] = [:]
    
    /// Running downloads currently active: taskIdentifier → task
    private var runningTasks: [UUID: URLSessionDownloadTask] = [:]
    
    /// Maximum Conucurrent Download
    private let maxConcurrentDownloads = 3
    
    /// All downloads managed by the manager. It will observed by the UI
    @Published var downloads: [DownloadItem] = []
    
    
    private var lastReportedProgress: [UUID: Float] = [:]
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default  // Use default for testing concurrency
        config.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    
    // MARK: - Public Downloading Methods

    // Start or Resume Download
    func statrtDownload(item: DownloadItem) {
        guard item.status == .pending else { return }
        
        // Mark the item as in progress and reset/resend current progress
        item.status = .inProgress
        item.progress = item.progress
        
        let task: URLSessionDownloadTask
        if let resumeData = item.resumeData {
            // Resume the download with the previous resume data
            task = urlSession.downloadTask(withResumeData: resumeData)
            item.resumeData = nil
            DownloadActivityManager.shared.updateActivity(id: item.id.uuidString, status: .inpogress, progress: (Int(item.progress * 100)))
        } else {
            // Start new download
            task = urlSession.downloadTask(with: item.url)
            DownloadActivityManager.shared.startActivity(id: item.id.uuidString, status: .inpogress, fileName: item.fileName, progress: (Int(item.progress * 100)))
        }
        
        runningTasks[item.id] = task
        taskMap[task.taskIdentifier] = item
        task.resume()
        
    }
    
    
    /// Pause an in-progress download, saving resuke data if supported.
    func pauseDownload(item: DownloadItem) {
        guard item.status == .inProgress else { return }
        
        if let task = runningTasks[item.id] {
            // Cancel the task, but provide the resume data
            task.cancel { data in
                item.status = .pending
                item.resumeData = data
                item.progress = item.progress
                self.updateProgress(for: item)
                
                // Remove bookkeeping for the task
                self.runningTasks.removeValue(forKey: item.id)
                self.taskMap.removeValue(forKey: task.taskIdentifier)
            }
        }
    }
    
    
    /// Cancel the download
    func cancelDownload(_ item: DownloadItem) {
        item.status = .pending
        item.progress = 0
        item.resumeData = nil

        if let task = runningTasks[item.id] {
            task.cancel()
            runningTasks.removeValue(forKey: item.id)
            taskMap.removeValue(forKey: task.taskIdentifier)
        }

        self.updateProgress(for: item)
    }
    
    /// Set download urls
    func setDownloads(urls: [URL]) {
        downloads = urls.map { DownloadItem(url: $0, fileName: $0.lastPathComponent)}
    }
    
    
    /// update download progerss
//    private func updateProgress(for item: DownloadItem) {
//        DispatchQueue.main.async {
//            self.objectWillChange.send()
//            item.status = item.status
//            item.resumeData = item.resumeData
//                        
//            DownloadActivityManager.shared.updateActivity(id: item.id.uuidString, status: .inpogress, progress: (Int(item.progress * 100)))
//        }
//    }
    
    
    private func updateProgress(for item: DownloadItem) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            item.status = item.status
            item.resumeData = item.resumeData

            let currentProgress: Float = item.progress
            let lastProgress: Float = self.lastReportedProgress[item.id] ?? 0.0
            
            // Update if progress advanced by at least 1%
            let minProgressDifference: Float = 0.01
            
            guard currentProgress - lastProgress >= minProgressDifference || currentProgress == 1.0 else {
                // Skip update if progress change is too small and it's not complete
                return
            }
            
            self.lastReportedProgress[item.id] = currentProgress
            
            // Send progress as integer percent or as Double if your manager accepts fractional
            let progressPercent = Int(currentProgress * 100)
            
            DownloadActivityManager.shared.updateActivity(id: item.id.uuidString, status: .inpogress, progress: progressPercent)
        }
    }
    
    
}


extension MyDownloadManager: URLSessionDownloadDelegate {
    
    /// Delegate called as data writes, for progress updates
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let item = taskMap[downloadTask.taskIdentifier] else { return }
        let progress: Float = totalBytesExpectedToWrite > 0 ?
        Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) : 0
        
        DispatchQueue.main.async {
            item.progress = progress
            print("⏳  Download In progress - \(progress)")
            self.updateProgress(for: item)
        }
    }
    
    
    /// Delegate called when download finishes successfully
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let item = taskMap[downloadTask.taskIdentifier] else { return }
        
        do {
            // Save the file to disk using your app's file manager
            CRUDFileManager.shared.saveFile(at: location, name: item.fileName)
            
            // Notify completion
            DispatchQueue.main.async {
                item.status = .completed
                item.progress = 1.0
                self.updateProgress(for: item)
            }
            
        } catch {
            // Handling error in saving file
            DispatchQueue.main.async {
                item.status = .failed
                self.updateProgress(for: item)
            }
        }
    }
    
    /// Delegate called when task completes (either error, cancel, success, or resume)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let item = taskMap[task.taskIdentifier] {
            if let err = error as NSError?,
               let resumeData = err.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                // Save resume data if available
                DispatchQueue.main.async {
                    item.resumeData = resumeData
                    item.status = .pending
                    self.updateProgress(for: item)
                }
            } else if error != nil {
                // Handle failure with no resume support
                DispatchQueue.main.async {
                    item.status = .failed
                    self.updateProgress(for: item)
                }
            }

            // Clear bookkeeping for finished task
            runningTasks.removeValue(forKey: item.id)
            taskMap.removeValue(forKey: task.taskIdentifier)
            DownloadActivityManager.shared.endActivity(id: item.id.uuidString, status: .finish, progress: (Int(item.progress * 100)))
        }
    }
    
}
