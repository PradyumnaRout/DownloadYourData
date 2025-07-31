//
//  FileManager.swift
//  DownloadYourData
//
//  Created on 30/07/25.
//

import Foundation

class CRUDFileManager {
    static var shared: CRUDFileManager = CRUDFileManager()
    
    private init() {}
    
    
    func saveFile(at location: URL, name: String) {
        
        do {
            let fileManager = FileManager.default
            
            // Get app's Documents directory URL
            let docsDir = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            // Define your custom folder name inside Documents
            let customFolder = docsDir.appendingPathComponent("Downloads", isDirectory: true)
            
            // Create the folder if it doesn't exist
            if !fileManager.fileExists(atPath: customFolder.path) {
                try fileManager.createDirectory(at: customFolder, withIntermediateDirectories: true)
            }
            
            // Create destination file URL inside your custom folder
            let destURL = customFolder.appendingPathComponent(name)
            
            // Remove existing file if any to prevent errors
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            
            // Move the downloaded file from temp location to your custom folder location
            try fileManager.moveItem(at: location, to: destURL)
            
            print("✅ File saved to: \(destURL.path)")
            
        } catch {
            print("❌ Failed to move file: \(error.localizedDescription)")
        }
        
    }
    
}
