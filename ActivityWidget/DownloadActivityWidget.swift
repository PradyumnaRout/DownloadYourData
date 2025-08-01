//
//  DownloadActivityWidget.swift
//  DownloadYourData
//
//  Created by hb on 01/08/25.
//

import Foundation
import SwiftUI
import ActivityKit
import WidgetKit


struct DownloadActivityWidget: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DownloadActivityAttributes.self) { context in
            // Lock screen banner
            DownloadActivityContent(
                title: context.state.downloadStatus.rawValue,
                fileName: context.attributes.fileName,
                progressValue: context.state.progress
            )
                    
        } dynamicIsland: { context in
            // dynamic island
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DownloadLogo(size: 48)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    MinimalProgressBar(
                        progressValue: context.state.progress,
                        size: 48
                    )
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Find details in app")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                }
            } compactLeading: {
                DownloadLogo(size: 24)
            } compactTrailing: {
                MinimalProgressBar(
                    progressValue: context.state.progress,
                    size: 24
                )
            } minimal: {
                MinimalProgressBar(
                    progressValue: context.state.progress,
                    size: 24
                )
            }

        }

    }
}
