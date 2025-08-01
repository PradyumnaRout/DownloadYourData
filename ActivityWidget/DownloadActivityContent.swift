//
//  DownloadActivityContent.swift
//  DownloadYourData
//
//  Created by hb on 01/08/25.
//

import Foundation
import WidgetKit
import SwiftUI

struct DownloadActivityContent: View {
    
    let title: String
    let fileName: String
    let progressValue: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            HStack {
                Text(fileName)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
                
                Spacer()
                
                DownloadLogo(size: 25)
            }
            
            
            ProgressView(value: Float(progressValue), total: 100) {
                Text("Current progress: \(Int(progressValue))%")
            }
            .tint(.primary)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 20)
    }
}


struct DownloadLogo: View {
    
    let size: CGFloat
    
    var body: some View {
        Image("attachment")
            .resizable()
            .frame(width: size, height: size)
    }
}


struct MinimalProgressBar: View {
    
    let progressValue: Int
    let size: CGFloat
    
    var body: some View {
        ProgressView(value: Float(progressValue), total: 100) {
            Text("\(progressValue)")
        }
        .frame(width: size, height: size)
        .progressViewStyle(.circular)
        .tint(.primary)
    }
}
