//
//  AnyHostingDownloadView.swift
//  DownloadYourData
//
//  Created by hb on 31/07/25.
//

import SwiftUI

struct AnyHostingDownloadView: View {
    @ObservedObject private var manager = AnyHostConcurrentDownloadManager.shared

    var body: some View {
        NavigationView {
            List {
                ForEach(manager.downloads, id: \.id) { item in
                    AnyHostingDownloadRow(item: item)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Downloads")
            .onAppear {
                if manager.downloads.isEmpty {
                    let urls: [URL] = AppConstants.videoUrls
                    manager.setDownloads(urls: urls)
                }
            }
        }
    }
}

struct AnyHostingDownloadRow: View {
    @ObservedObject var item: DownloadItem

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(item.fileName)
                    .font(.headline)
                Spacer()
                Button(action: handleAction) {
                    Image(systemName: actionIconName())
                        .font(.title2)
                        .foregroundColor(actionIconColor())
                }
                .buttonStyle(BorderlessButtonStyle())

                if item.status == .inProgress || item.status == .pending || item.status == .failed {
                    Button(action: cancelAction) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            ProgressView(value: item.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.vertical, 4)

            Text("\(Int(item.progress * 100))% - \(item.status.rawValue.capitalized)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private func handleAction() {
        switch item.status {
        case .pending, .failed:
            AnyHostConcurrentDownloadManager.shared.downloadFile(with: item)
        case .inProgress:
            AnyHostConcurrentDownloadManager.shared.pauseDownload(item: item)
        case .completed:
            print("Download completed")
        }
    }

    private func cancelAction() {
        AnyHostConcurrentDownloadManager.shared.cancelDownload(item)
    }

    private func actionIconName() -> String {
        switch item.status {
        case .pending, .failed:
            return "arrow.down.circle"
        case .inProgress:
            // Appears for both running and queued downloads
            return "pause.circle"
        case .completed:
            return "checkmark.circle"
        }
    }

    private func actionIconColor() -> Color {
        switch item.status {
        case .pending, .failed: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
}

