//
//  MyDownloadManager.swift
//  DownloadYourData
//
//  Created on 17/07/25.
//

import Foundation
import UIKit

class MyDownloadManager: NSObject, ObservableObject {
    
    static var shared = MyDownloadManager()
    
    private var urlSession: URLSession!
    private var taskMap: [Int: DownloadItem] = [:]
    
    private var runningTasks: [Int: URLSessionDownloadTask] = [:]
    private var pendingQueue: [DownloadItem] = []
        
    private let maxConcurrentDownloads = 3
    private var backgroundCompletionHandlers: [String: () -> Void] = [:]
    
    @Published var downloads: [DownloadItem] = []
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "MyDowload.background.tasks")
        config.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        config.sessionSendsLaunchEvents = true
        // Warning: Make sure that the URLSession is created only once (if an URLSession still
        // exists from a previous download, it doesn't create a new URLSession object but returns
        // the existing one with the old delegate object attached)
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    func enqueueDownloads(urls: [URL]) {
        for (i, url) in urls.enumerated() {
            let item = DownloadItem(url: url, fileName: "File\(i + 1).\(url.pathExtension)")
            downloads.append(item)
            pendingQueue.append(item)
        }
        startNextDownloadsIfNeeded()
    }
    
    private func startNextDownloadsIfNeeded() {
        while runningTasks.count < maxConcurrentDownloads && !pendingQueue.isEmpty {
            let item = pendingQueue.removeFirst()
            startDownload(item)
        }
    }
    
    private func startDownload(_ item: DownloadItem) {
        var updatedItem = item
        updatedItem.status = .inProgress
        
        guard let index = downloads.firstIndex(where: { $0.id == item.id }) else { return }
        downloads[index] = updatedItem
        
        let task = urlSession.downloadTask(with: item.url)
        taskMap[task.taskIdentifier] = updatedItem
        runningTasks[task.taskIdentifier] = task
        
        task.resume()
    }

    private func updateProgress(for task: URLSessionDownloadTask, progress: Float) {
        guard var item = taskMap[task.taskIdentifier],
              let index = downloads.firstIndex(where: { $0.id == item.id }) else { return }
        
        item.progress = progress
        downloads[index] = item
    }
    
    private func complete(task: URLSessionDownloadTask, success: Bool) {
        guard var item = taskMap[task.taskIdentifier],
              let index = downloads.firstIndex(where: { $0.id == item.id }) else { return }
        
        item.status = success ? .completed : .failed
        item.progress = 1.0
        downloads[index] = item
        
        taskMap.removeValue(forKey: task.taskIdentifier)
        runningTasks.removeValue(forKey: task.taskIdentifier)
        
        startNextDownloadsIfNeeded()
    }
    
    // The below two will call
    func storeCompletionHandler(_ identifier: String, _ handler: @escaping () -> Void) {
        backgroundCompletionHandlers[identifier] = handler
        print("Storing Completion.....")
    }

    func callCompletionHandler(for identifier: String) {
        guard let handler = backgroundCompletionHandlers[identifier] else {
            print(" No completion handler found for ID: \(identifier)")
            return
        }
        
        print(" Calling background completion handler for ID: \(identifier)")
        handler()
        backgroundCompletionHandlers.removeValue(forKey: identifier)
    }
    
    // Persist the inprogress tasks
    func persistInProgressTasks() {
        let inProgressItems = downloads.filter { $0.status == .inProgress }
        let urls = inProgressItems.map { $0.url.absoluteString }
        UserDefaults.standard.set(urls, forKey: "PendingDownloadURLs")
    }
    
    // Resume the inprogress download.
    func resumePersistedDownloads() {
        if let urlStrings = UserDefaults.standard.array(forKey: "PendingDownloadURLs") as? [String] {
            let urls = urlStrings.compactMap { URL(string: $0) }
            enqueueDownloads(urls: urls)
            UserDefaults.standard.removeObject(forKey: "PendingDownloadURLs") // Clean up
        }
    }
    
    func pauseAllRunningTasks() {
        if !pendingQueue.isEmpty {
            let urls = downloads.map { $0.url.absoluteString }
            UserDefaults.standard.set(urls, forKey: "allDownloads")
            for (_, task) in runningTasks {
                task.suspend()
            }
        }
    }
    
    func resumeAllRunningTasks() {
        if !pendingQueue.isEmpty {
            if let urlStrings = UserDefaults.standard.array(forKey: "allDownloads") as? [String] {
                let urls = urlStrings.compactMap { URL(string: $0) }
                enqueueDownloads(urls: urls)
                UserDefaults.standard.removeObject(forKey: "allDownloads") // Clean up
            }
            for (_, task) in runningTasks {
                if task.state == .suspended {
                    task.resume()
                }
            }
        }
    }
    
}

extension MyDownloadManager: URLSessionDelegate, URLSessionDownloadDelegate {

    // For Upload progress
//    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
//
//    }
    
    // For Download progress
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress: Float
//        print("Progress -- \(totalBytesExpectedToWrite)")
        if totalBytesExpectedToWrite > 0 {
            progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        } else {
            progress = 0.0
        }
        updateProgress(for: downloadTask, progress: progress)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let item = taskMap[downloadTask.taskIdentifier] else { return }
        let fileName = item.fileName
        
        // Create Document URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appending(path: fileName)
        
        // Move file to destination location
        do {
            // Ensure destination folder exists (usually always does)
            if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
                try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
            }
            
            // Ensure the source file actually exists before trying to move
            guard FileManager.default.fileExists(atPath: location.path) else {
                print("❌ Source file does not exist at: \(location.path)")
                return
            }
            
            //  Remove old file if needed
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Move file
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("✅ File moved to \(destinationURL.lastPathComponent)")
        } catch {
            print("❌ Error saving file: \(error.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let response = task.response as? HTTPURLResponse {
                print("Status code: \(response.statusCode), URL: \(task.originalRequest?.url?.absoluteString ?? "")")
            }
            
            if let error = error {
                print("❌ Download error: \(error)")
            } else {
                print("✅ Download finished: \(task.originalRequest?.url?.absoluteString ?? "")")
            }

        
        
        complete(task: task as! URLSessionDownloadTask, success: error == nil)
        if pendingQueue.isEmpty {
            //If you call it inside didCompleteWithError for every task, and multiple downloads are ongoing, iOS may suspend your app prematurely.
            MyDownloadManager.shared.callCompletionHandler(for: session.configuration.identifier ?? "")
        }
    }
    
}


