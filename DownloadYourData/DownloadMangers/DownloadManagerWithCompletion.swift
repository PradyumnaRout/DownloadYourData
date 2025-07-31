//
//  DownloadManagerWithCompletion.swift
//  DownloadYourData
//
//  Created on 30/07/25.
//

import Foundation


class DownloadManagerWithCompletion: NSObject {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = DownloadManagerWithCompletion()

    /// The underlying URLSession
    private var urlSession: URLSession!
    
    /// Max number of concurrent downloads allowed
    private let maxConcurrentDownloads = 3
    
    /// Active download tasks by item UUID
    private var runningTasks: [UUID: URLSessionDownloadTask] = [:]
    
    /// Maps URLSession's taskIdentifier to our DownloadItem instance
    private var itemMap: [Int: DownloadItem] = [:]
    
    /// Callback triggered whenever progress/status needs to be published
    var onProgressUpdate: ((DownloadItem) -> Void)?
    

    // MARK: - Initialization

    /// Private init for singleton
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "download.background")
        config.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    
    // MARK: - Public Downloading Methods

    /// Start downloading given item, or resume if pause data is available
    func startDownload(item: DownloadItem) {
        guard item.status == .pending else { return }

        // Mark the item as in progress and reset/resend current progress
        item.status = .inProgress
        item.progress = item.progress
        onProgressUpdate?(item)
        
        let task: URLSessionDownloadTask
        if let resumeData = item.resumeData {
            // Resume interrupted download
            task = urlSession.downloadTask(withResumeData: resumeData) // Resume the download with the resume data
            item.resumeData = nil
        } else {
            // Start new download
            task = urlSession.downloadTask(with: item.url)
        }
        
        // Book-keeping so we can update the right item on delegate callbacks
        runningTasks[item.id] = task
        itemMap[task.taskIdentifier] = item
        task.resume()
    }

    /// Pause an in-progress download, saving resume data if supported
    func pauseDownload(item: DownloadItem) {
        guard item.status == .inProgress else { return }

        if let task = runningTasks[item.id] {
            // Cancel the task, but provide resume data (if server supports)
            task.cancel(byProducingResumeData: { data in
                DispatchQueue.main.async {
                    item.status = .pending
                    item.resumeData = data          // Save so we can resume later
                    item.progress = item.progress   // Also triggers UI update
                    self.onProgressUpdate?(item)
                }
                
                // Remove bookkeeping for this task
                self.runningTasks.removeValue(forKey: item.id)
                self.itemMap.removeValue(forKey: task.taskIdentifier)
            })
        }
    }

}

// MARK: - URLSessionDownloadDelegate

extension DownloadManagerWithCompletion: URLSessionDownloadDelegate {
    
    /// Delegate called as data writes, for progress updates
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let item = itemMap[downloadTask.taskIdentifier] else { return }
        let progress: Float = totalBytesExpectedToWrite > 0 ?
            Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) : 0
        DispatchQueue.main.async {
            item.progress = progress
            print("⏳  Download progress - \(progress)")
            self.onProgressUpdate?(item)
        }
    }

    /// Delegate called when download finishes successfully
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let item = itemMap[downloadTask.taskIdentifier] else { return }
        
        do {
            // Save the file to disk using your app's file manager
            CRUDFileManager.shared.saveFile(at: location, name: item.fileName)
            
            // Notify completion
            DispatchQueue.main.async {
                item.status = .completed
                item.progress = 1.0
                self.onProgressUpdate?(item)
            }
            
        } catch {
            // Handling error in saving file
            DispatchQueue.main.async {
                item.status = .failed
                self.onProgressUpdate?(item)
            }
        }
    }


    /// Delegate called when task completes (either error, cancel, success, or resume)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let item = itemMap[task.taskIdentifier] {
            if let err = error as NSError?,
               let resumeData = err.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                // Save resume data if available
                DispatchQueue.main.async {
                    item.resumeData = resumeData
                    item.status = .pending
                    self.onProgressUpdate?(item)
                }
            } else if error != nil {
                // Handle failure with no resume support
                DispatchQueue.main.async {
                    item.status = .failed
                    self.onProgressUpdate?(item)
                }
            }

            // Clear bookkeeping for finished task
            runningTasks.removeValue(forKey: item.id)
            itemMap.removeValue(forKey: task.taskIdentifier)
        }
    }

}
