//
//  GalleryViewModel.swift
//  SamplTestApp
//
//  Updated with offline image caching support
//

import Foundation
internal import CoreData
import Combine

class GalleryViewModel: ObservableObject {
    @Published var images: [WallpaperImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var downloadProgress: [String: Double] = [:] // Track download progress per image
    
    private var currentPage = 1
    private let itemsPerPage = 20
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    private let cacheManager = ImageCacheManager.shared
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadOfflineImages()
    }
    
    func fetchImages() {
        guard !isLoading else { return }
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            let staticImages = self.getStaticImages()
            self.images.append(contentsOf: staticImages)
            self.saveToDatabase(staticImages)
            
            // Download thumbnails for offline use
            self.downloadThumbnails(for: staticImages)
            
            self.isLoading = false
            self.currentPage += 1
        }
    }
    
    // Download thumbnails in background
    private func downloadThumbnails(for wallpapers: [WallpaperImage]) {
        for wallpaper in wallpapers {
            // Skip if already downloaded
            if cacheManager.imageExists(for: wallpaper.id) {
                continue
            }
            
            cacheManager.downloadAndSaveImage(from: wallpaper.thumbnailURL, imageId: wallpaper.id) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Downloaded thumbnail for: \(wallpaper.id)")
                        // Update the specific image's cache status
                        self?.updateImageCacheStatus(wallpaper.id)
                    } else {
                        print("❌ Failed to download: \(wallpaper.id)")
                    }
                }
            }
        }
    }
    
    private func updateImageCacheStatus(_ imageId: String) {
        // Notify views that cache status changed
        if let index = images.firstIndex(where: { $0.id == imageId }) {
            // Trigger view update by modifying the array
            let image = images[index]
            images[index] = image
        }
    }
    
    // Check if image is cached locally
    func isImageCached(_ imageId: String) -> Bool {
        return cacheManager.imageExists(for: imageId)
    }
    
    // Get local image path
    func getLocalImageURL(_ imageId: String) -> URL? {
        if cacheManager.imageExists(for: imageId) {
            return cacheManager.localImagePath(for: imageId)
        }
        return nil
    }
    
    private func getStaticImages() -> [WallpaperImage] {
        let baseImages = [
            WallpaperImage(
                id: "1",
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
                thumbnailURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400",
                author: "Mountain View"
            ),
            WallpaperImage(
                id: "2",
                imageURL: "https://images.unsplash.com/photo-1469474968028-56623f02e42e",
                thumbnailURL: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400",
                author: "Forest Path"
            ),
            WallpaperImage(
                id: "3",
                imageURL: "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05",
                thumbnailURL: "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=400",
                author: "Misty Valley"
            ),
            WallpaperImage(
                id: "4",
                imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e",
                thumbnailURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400",
                author: "Desert Landscape"
            ),
            WallpaperImage(
                id: "5",
                imageURL: "https://images.unsplash.com/photo-1426604966848-d7adac402bff",
                thumbnailURL: "https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=400",
                author: "Lake Reflection"
            ),
            WallpaperImage(
                id: "6",
                imageURL: "https://images.unsplash.com/photo-1502082553048-f009c37129b9",
                thumbnailURL: "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400",
                author: "Ocean Waves"
            ),
            WallpaperImage(
                id: "7",
                imageURL: "https://images.unsplash.com/photo-1472214103451-9374bd1c798e",
                thumbnailURL: "https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=400",
                author: "Tropical Beach"
            ),
            WallpaperImage(
                id: "8",
                imageURL: "https://images.unsplash.com/photo-1475924156734-496f6cac6ec1",
                thumbnailURL: "https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?w=400",
                author: "Snowy Mountains"
            ),
            WallpaperImage(
                id: "9",
                imageURL: "https://images.unsplash.com/photo-1501854140801-50d01698950b",
                thumbnailURL: "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=400",
                author: "City Skyline"
            ),
            WallpaperImage(
                id: "10",
                imageURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
                thumbnailURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400",
                author: "Sunset Beach"
            ),
            WallpaperImage(
                id: "11",
                imageURL: "https://images.unsplash.com/photo-1519681393784-d120267933ba",
                thumbnailURL: "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400",
                author: "Night Sky"
            ),
            WallpaperImage(
                id: "12",
                imageURL: "https://images.unsplash.com/photo-1511884642898-4c92249e20b6",
                thumbnailURL: "https://images.unsplash.com/photo-1511884642898-4c92249e20b6?w=400",
                author: "Autumn Forest"
            ),
            WallpaperImage(
                id: "13",
                imageURL: "https://images.unsplash.com/photo-1518837695005-2083093ee35b",
                thumbnailURL: "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400",
                author: "Flower Field"
            ),
            WallpaperImage(
                id: "14",
                imageURL: "https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07",
                thumbnailURL: "https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?w=400",
                author: "Green Hills"
            ),
            WallpaperImage(
                id: "15",
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
                thumbnailURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400",
                author: "Rocky Coast"
            ),
            WallpaperImage(
                id: "16",
                imageURL: "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d",
                thumbnailURL: "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=400",
                author: "Wildlife Scene"
            ),
            WallpaperImage(
                id: "17",
                imageURL: "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429",
                thumbnailURL: "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=400",
                author: "Waterfall"
            ),
            WallpaperImage(
                id: "18",
                imageURL: "https://images.unsplash.com/photo-1481627834876-b7833e8f5570",
                thumbnailURL: "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400",
                author: "Northern Lights"
            ),
            WallpaperImage(
                id: "19",
                imageURL: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b",
                thumbnailURL: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400",
                author: "Peak Summit"
            ),
            WallpaperImage(
                id: "20",
                imageURL: "https://images.unsplash.com/photo-1505142468610-359e7d316be0",
                thumbnailURL: "https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=400",
                author: "Urban Night"
            ),
            WallpaperImage(
                id: "21",
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
                thumbnailURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400",
                author: "Mountain View1"
            ),
            WallpaperImage(
                id: "22",
                imageURL: "https://images.unsplash.com/photo-1469474968028-56623f02e42e",
                thumbnailURL: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400",
                author: "Forest Path1"
            ),
            WallpaperImage(
                id: "23",
                imageURL: "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05",
                thumbnailURL: "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=400",
                author: "Misty Valley1"
            ),
            WallpaperImage(
                id: "24",
                imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e",
                thumbnailURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400",
                author: "Desert Landscape1"
            ),
            WallpaperImage(
                id: "25",
                imageURL: "https://images.unsplash.com/photo-1426604966848-d7adac402bff",
                thumbnailURL: "https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=400",
                author: "Lake Reflection1"
            ),
            WallpaperImage(
                id: "26",
                imageURL: "https://images.unsplash.com/photo-1502082553048-f009c37129b9",
                thumbnailURL: "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400",
                author: "Ocean Waves1"
            ),
            WallpaperImage(
                id: "27",
                imageURL: "https://images.unsplash.com/photo-1472214103451-9374bd1c798e",
                thumbnailURL: "https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=400",
                author: "Tropical Beach1"
            ),
            WallpaperImage(
                id: "28",
                imageURL: "https://images.unsplash.com/photo-1475924156734-496f6cac6ec1",
                thumbnailURL: "https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?w=400",
                author: "Snowy Mountains1"
            ),
            WallpaperImage(
                id: "29",
                imageURL: "https://images.unsplash.com/photo-1501854140801-50d01698950b",
                thumbnailURL: "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=400",
                author: "City Skyline1"
            ),
            WallpaperImage(
                id: "30",
                imageURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
                thumbnailURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400",
                author: "Sunset Beach 1"
            ),
        ]
        
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, baseImages.count)
        
        guard startIndex < baseImages.count else { return [] }
        
        return Array(baseImages[startIndex..<endIndex])
    }
    
    private func saveToDatabase(_ wallpapers: [WallpaperImage]) {
        for wallpaper in wallpapers {
            let fetchRequest: NSFetchRequest<ImageEntity> = ImageEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", wallpaper.id)
            
            do {
                let existing = try context.fetch(fetchRequest)
                if existing.isEmpty {
                    let entity = ImageEntity(context: context)
                    entity.id = wallpaper.id
                    entity.imageURL = wallpaper.imageURL
                    entity.thumnailURl = wallpaper.thumbnailURL
                    entity.author = wallpaper.author
                }
            } catch {
                print("Error checking existing: \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save to database: \(error)")
        }
    }
    
    private func loadOfflineImages() {
        let fetchRequest: NSFetchRequest<ImageEntity> = ImageEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            images = entities.map { WallpaperImage(from: $0) }
        } catch {
            print("Failed to load offline images: \(error)")
        }
    }
    
    // Get cache size for display
    func getCacheSizeString() -> String {
        let bytes = cacheManager.getCacheSize()
        let mb = Double(bytes) / (1024 * 1024)
        return String(format: "%.2f MB", mb)
    }
    
    // Clear cache
    func clearCache() {
        cacheManager.clearCache()
    }
}
