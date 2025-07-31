//
//  DownloadViewModel.swift
//  DownloadYourData
//
//  Created on 17/07/25.
//

import Foundation
import Combine

class DownloadViewModel: ObservableObject {
    @Published var downloads: [DownloadItem] = []

    init() {
        for (i, url) in AppConstants.videoUrls.enumerated() {
            downloads.append(DownloadItem(url: url, fileName: "File\(i+1).bin"))
        }

        DownloadManagerWithCompletion.shared.onProgressUpdate = { [weak self] item in
            guard let self else { return }
            if let idx = self.downloads.firstIndex(where: { $0.id == item.id }) {
                DispatchQueue.main.async {
                    
                    /// The expression self.objectWillChange.send() in a SwiftUI ViewModel that conforms to ObservableObject is used to manually notify all observers (typically Views) that the object is about to change, so that SwiftUI can re-render the UI accordingly
                    self.objectWillChange.send()
                    self.downloads[idx].status = item.status
                    self.downloads[idx].progress = item.progress
                    self.downloads[idx].resumeData = item.resumeData
                }
            }
        }
    }

    func toggleDownload(for item: DownloadItem) {
        switch item.status {
        case .pending:
            DownloadManagerWithCompletion.shared.startDownload(item: item)
        case .inProgress:
            DownloadManagerWithCompletion.shared.pauseDownload(item: item)
        default:
            break
        }
    }
}
