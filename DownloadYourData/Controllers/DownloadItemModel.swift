//
//  DownloadItemMode.swift
//  DownloadYourData
//
//  Created on 17/07/25.
//

import Foundation

struct DownloadItem: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    var progress: Float = 0.0
    var status: DownloadStatus = .pending

    enum DownloadStatus: String {
        case pending
        case inProgress
        case completed
        case failed
    }
}
