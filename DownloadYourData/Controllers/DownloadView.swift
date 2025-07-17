//
//  DownloadView.swift
//  DownloadYourData
//
//  Created on 17/07/25.
//

import SwiftUI

struct DownloadView: View {
    
    @ObservedObject var manager = MyDownloadManager.shared
    
    var body: some View {
        NavigationView {
            List(manager.downloads) { item in
                VStack(alignment: .leading) {
                    Text(item.fileName)
                        .font(.headline)
                    
                    ProgressView(value: item.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.vertical, 4)
                    
                    Text("\(Int(item.progress * 100))% - \(item.status.rawValue.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Downloads")
        }
    }
}



struct DownloadContentView: View {
    
//    let urls: [URL] = [
//        URL(string: "https://file-examples.com/storage/fe2a95a9cc3d4ef073fc3aa/2017/10/file-sample_150kB.pdf")!,
//        URL(string: "https://file-examples.com/storage/fe2a95a9cc3d4ef073fc3aa/2017/11/file_example_MP4_480_1_5MG.mp4")!,
//        URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
//        URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_5mb.mp4")!,
//        URL(string: "https://file-examples.com/storage/fe2a95a9cc3d4ef073fc3aa/2017/02/file_example_CSV_5000.csv")!,
//        URL(string: "https://file-examples.com/storage/fe2a95a9cc3d4ef073fc3aa/2017/11/file_example_MP3_1MG.mp3")!,
//        URL(string: "https://sample-videos.com/audio/mp3/wave.mp3")!,
//        URL(string: "https://sample-videos.com/pdf/Sample-pdf-5mb.pdf")!,
//        URL(string: "https://file-examples.com/wp-content/uploads/2017/10/file_example_JPG_10MB.jpg")!,
//        URL(string: "https://file-examples.com/wp-content/uploads/2017/02/file_example_XLS_10.xls")!
//    ]
    
    let urls: [URL] = [
        URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4")!,
        URL(string: "https://filesamples.com/samples/video/mp4/sample_1280x720_surfing_with_audio.mp4")!,
        URL(string: "https://filesamples.com/samples/video/mp4/sample_1280x720.mp4")!,
        URL(string: "https://filesamples.com/samples/video/mp4/sample_1920x1080.mp4")!,
        URL(string: "https://www.learningcontainer.com/wp-content/uploads/2019/09/sample-pdf-download-10-mb.pdf")!,
        URL(string: "https://www.learningcontainer.com/download/sample-50-mb-pdf-file/")!,
        URL(string: "https://sampledocs.in/sampledocs-50mb-xls-file.xls")!,
        URL(string: "https://all-free-download.com/free-footage/mp4-video-nature-free-50-mb/nature-footage.mp4")!,
        URL(string: "https://sampledocs.in/sample_file_50mb_sampledocs.txt")!,
        URL(string: "https://sampledocs.in/sampledocs-50mb-xlsx-file.xlsx")!
    ]
    
    var body: some View {
        VStack {
            DownloadView()
            Button("Start 10 Downloads") {
                MyDownloadManager.shared.enqueueDownloads(urls: urls)
            }
            .padding()
        }
    }
}


#Preview {
    DownloadView()
}
