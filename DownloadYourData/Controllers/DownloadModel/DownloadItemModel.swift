//
//  DownloadItemMode.swift
//  DownloadYourData
//
//  Created on 17/07/25.
//

import Foundation

import Foundation

enum DownloadStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

class DownloadItem: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    let fileName: String
    @Published var progress: Float = 0.0
    @Published var status: DownloadStatus = .pending
    var resumeData: Data?

    init(url: URL, fileName: String) {
        self.url = url
        self.fileName = fileName
    }
}
