//
//  AnyHostConcurrentDownloadManager.swift
//  DownloadYourData
//
//  Created by hb on 31/07/25.
//

import Foundation
import Combine


class AnyHostConcurrentDownloadManager: NSObject, ObservableObject {
    
    static let shared = AnyHostConcurrentDownloadManager()
    private var urlSession: URLSession!
    
    /// Maps URLSessionDownloadTask taskIdentifier → DownloadItem
    private var taskMap: [Int: DownloadItem] = [:]
    /// Running downloads currently active: item.id → URLSessionDownloadTask
    private var runningTasks: [UUID: URLSessionDownloadTask] = [:]
    /// Downloads *waiting in queue*, only started when concurrency allows
    private var pendingQueue: [DownloadItem] = []
    
    /// Maximum concurrent downloads *total* (regardless of host)
    private let maxConcurrentDownloads = 3

    /// All downloads managed by the manager. Observed by the UI.
    @Published var downloads: [DownloadItem] = []
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    /// Initialize downloads list without starting any download automatically.
    func setDownloads(urls: [URL]) {
        downloads = urls.map { DownloadItem(url: $0, fileName: $0.lastPathComponent) }
        // Clear any existing queue
        pendingQueue.removeAll()
        // Note: Don't add any to pending queue yet, wait for user action
    }
    
    /// Called by UI to start or queue a download for an item.
    func downloadFile(with item: DownloadItem) {
        switch item.status {
        case .pending, .failed:
            if runningTasks.count < maxConcurrentDownloads {
                startDownload(item: item) // start immediately
            } else {
                // Queue and mark as inProgress to show pause icon for queued item
                if !pendingQueue.contains(where: { $0.id == item.id }) && !runningTasks.keys.contains(item.id) {
                    pendingQueue.append(item)
                    DispatchQueue.main.async {
                        item.status = .inProgress
                        self.updateProgress(for: item)
                    }
                }
            }
        case .inProgress:
            // Already running or queued, no action here
            break
        case .completed:
            // Already downloaded - no action
            break
        }
    }
    
    /// Starts the actual download task. Called internally only.
    private func startDownload(item: DownloadItem) {
        // Remove from queue if present
        pendingQueue.removeAll { $0.id == item.id }
        
        DispatchQueue.main.async {
            item.status = .inProgress
            self.updateProgress(for: item)
        }
        
        let task: URLSessionDownloadTask
        if let resumeData = item.resumeData {
            task = urlSession.downloadTask(withResumeData: resumeData)
            item.resumeData = nil
        } else {
            task = urlSession.downloadTask(with: item.url)
        }
        
        runningTasks[item.id] = task
        taskMap[task.taskIdentifier] = item
        task.resume()
    }
    
    /// Starts queued downloads if there is capacity.
    func startNextAvailableDownloads() {
        // Start downloads for items in queue having status .inProgress or .pending
        while runningTasks.count < maxConcurrentDownloads, !pendingQueue.isEmpty {
            let next = pendingQueue.removeFirst()
            if next.status == .inProgress || next.status == .pending {
                startDownload(item: next)
            }
        }
    }
    
    /// Pause an in-progress download
    func pauseDownload(item: DownloadItem) {
        guard item.status == .inProgress else { return }
        if let task = runningTasks[item.id] {
            task.cancel { data in
                DispatchQueue.main.async {
                    item.status = .pending
                    item.resumeData = data
                    self.updateProgress(for: item)
                }
                self.runningTasks.removeValue(forKey: item.id)
                self.taskMap.removeValue(forKey: task.taskIdentifier)
                self.pendingQueue.removeAll { $0.id == item.id }
                self.startNextAvailableDownloads()
            }
        }
    }
    
    /// Cancel a download completely
    func cancelDownload(_ item: DownloadItem) {
        item.status = .pending
        item.progress = 0
        item.resumeData = nil
        
        if let task = runningTasks[item.id] {
            task.cancel()
            runningTasks.removeValue(forKey: item.id)
            taskMap.removeValue(forKey: task.taskIdentifier)
        }
        
        // Remove from pending queue
        pendingQueue.removeAll { $0.id == item.id }
        
        updateProgress(for: item)
        startNextAvailableDownloads()
    }
    
    /// Update UI (send objectWillChange)
    private func updateProgress(for item: DownloadItem) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}

extension AnyHostConcurrentDownloadManager: URLSessionDownloadDelegate {
    
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
            self.updateProgress(for: item)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let item = taskMap[downloadTask.taskIdentifier] else { return }
        do {
            CRUDFileManager.shared.saveFile(at: location, name: item.fileName)
            DispatchQueue.main.async {
                item.status = .completed
                item.progress = 1.0
                self.updateProgress(for: item)
            }
        } catch {
            DispatchQueue.main.async {
                item.status = .failed
                self.updateProgress(for: item)
            }
        }
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let item = taskMap[task.taskIdentifier] {
            if let err = error as NSError?,
               let resumeData = err.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                DispatchQueue.main.async {
                    item.resumeData = resumeData
                    item.status = .pending
                    self.updateProgress(for: item)
                }
            } else if error != nil {
                DispatchQueue.main.async {
                    item.status = .failed
                    self.updateProgress(for: item)
                }
            }
            
            runningTasks.removeValue(forKey: item.id)
            taskMap.removeValue(forKey: task.taskIdentifier)
            startNextAvailableDownloads()
        }
    }
}
