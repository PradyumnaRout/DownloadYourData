//
//  HomeView.swift
//  DownloadYourData
//
//  Created by hb on 30/07/25.
//

import SwiftUI

import SwiftUI

import SwiftUI

struct HomeView: View {
    @StateObject private var vm = DownloadViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(vm.downloads) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.fileName)
                                .font(.headline)

                            ProgressView(value: item.progress)
                                .progressViewStyle(LinearProgressViewStyle())

                            Text("\(Int(item.progress * 100))% - \(item.status.rawValue.capitalized)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()

                        Image(systemName: icon(for: item))
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(color(for: item))
                            .onTapGesture {
                                withAnimation { vm.toggleDownload(for: item) }
                            }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Downloads")
        }
    }

    private func icon(for item: DownloadItem) -> String {
        switch item.status {
        case .pending: return "arrow.down.to.line.circle.fill" 
        case .inProgress: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    private func color(for item: DownloadItem) -> Color {
        switch item.status {
        case .completed: return .green
        case .failed: return .red
        default: return .blue
        }
    }
}



#Preview {
    HomeView()
}
