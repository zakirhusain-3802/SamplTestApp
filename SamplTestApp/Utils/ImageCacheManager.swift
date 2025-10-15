//
//  ImageCacheManager.swift
//  SamplTestApp
//
//  Created by mac2 on 15/10/25.
//


//
//  ImageCacheManager.swift
//  SamplTestApp
//
//  Image caching manager for offline support
//

import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let fileManager = FileManager.default
    private var cacheDirectory: URL
    
    private init() {
        // Create cache directory in Documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // Generate local file path for an image ID
    func localImagePath(for imageId: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(imageId).jpg")
    }
    
    // Check if image exists locally
    func imageExists(for imageId: String) -> Bool {
        let path = localImagePath(for: imageId)
        return fileManager.fileExists(atPath: path.path)
    }
    
    // Download and save image thumbnail
    func downloadAndSaveImage(from urlString: String, imageId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        // Check if already cached
        if imageExists(for: imageId) {
            completion(true)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = UIImage(data: data) else {
                completion(false)
                return
            }
            
            // Compress image to reduce size
            let compressedData = self.compressImage(image, maxSizeKB: 200)
            
            do {
                let localPath = self.localImagePath(for: imageId)
                try compressedData.write(to: localPath)
                completion(true)
            } catch {
                print("Failed to save image: \(error)")
                completion(false)
            }
        }.resume()
    }
    
    // Load image from local storage
    func loadLocalImage(for imageId: String) -> UIImage? {
        let path = localImagePath(for: imageId)
        guard let data = try? Data(contentsOf: path) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    // Compress image to reduce file size
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression) ?? Data()
        
        // Reduce quality until size is acceptable
        while imageData.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression) ?? Data()
        }
        
        return imageData
    }
    
    // Clear all cached images (optional - for settings)
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // Get total cache size
    func getCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        return files.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + Int64(size)
        }
    }
}