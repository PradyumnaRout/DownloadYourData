//
//  DownloadActivityAttributes.swift
//  DownloadYourData
//
//  Created by hb on 01/08/25.
//

import Foundation
import ActivityKit

enum ActivityStatus: String, Codable {
    case inpogress = "Inprogress..."
    case finish = "Download Finished"
}

struct DownloadActivityAttributes: ActivityAttributes {
    
    // Dynamic Data
    public struct ContentState: Codable, Hashable {
        var downloadStatus: ActivityStatus
        var progress: Int
    }
    
    // Attribute
    var fileName: String
}
