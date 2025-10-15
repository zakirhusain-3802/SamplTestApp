//
//  GalleryView.swift
//  SamplTestApp
//
//  Created by mac2 on 15/10/25.
//  Updated with offline caching support
//

import SwiftUI
import Kingfisher
internal import CoreData

struct GalleryView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel: GalleryViewModel
    @State private var showCacheAlert = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: GalleryViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.images) { image in
                        NavigationLink(destination: ImageDetailView(image: image, viewModel: viewModel)) {
                            ImageCell(image: image, viewModel: viewModel)
                        }
                        .onAppear {
                            // Pagination: load more when reaching end
                            if image.id == viewModel.images.last?.id {
                                viewModel.fetchImages()
                            }
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Gallery")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.fetchImages()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            showCacheAlert = true
                        }) {
                            Label("Cache: \(viewModel.getCacheSizeString())", systemImage: "info.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            viewModel.clearCache()
                        }) {
                            Label("Clear Cache", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                if viewModel.images.isEmpty {
                    viewModel.fetchImages()
                }
            }
            .refreshable {
                viewModel.fetchImages()
            }
            .alert("Cache Info", isPresented: $showCacheAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Total cache size: \(viewModel.getCacheSizeString())\n\nImages are automatically downloaded for offline viewing.")
            }
        }
    }
}

struct ImageCell: View {
    let image: WallpaperImage
    @ObservedObject var viewModel: GalleryViewModel
    @State private var localImage: UIImage?
    @State private var shouldUseCache = false
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                if shouldUseCache, let localImage = localImage {
                    // Show cached local image
                    Image(uiImage: localImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    // Load from network with Kingfisher
                    KFImage(URL(string: image.thumbnailURL))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView())
                        }
                        .onFailure { error in
                            // If network fails, try to load from cache
                            loadLocalImage()
                        }
                        .onSuccess { _ in
                            // Image loaded from network successfully
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(10)
                }
                
                
            }
            
           
        }
        .onAppear {
            loadLocalImage()
        }
    }
    
    private func loadLocalImage() {
        if let localURL = viewModel.getLocalImageURL(image.id),
           let imageData = try? Data(contentsOf: localURL),
           let uiImage = UIImage(data: imageData) {
            self.localImage = uiImage
            self.shouldUseCache = true
        }
    }
}

struct ImageDetailView: View {
    let image: WallpaperImage
    @ObservedObject var viewModel: GalleryViewModel
    @State private var localFullImage: UIImage?
    @State private var showSaveSuccess = false
    
    var body: some View {
        ScrollView {
            VStack {
                // Try to show cached image first, otherwise load from network
                if let localFullImage = localFullImage {
                    Image(uiImage: localFullImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    KFImage(URL(string: image.imageURL))
                        .placeholder {
                            ProgressView()
                        }
                        .onSuccess { result in
                            // Optionally cache full image too
                            self.localFullImage = result.image
                        }
                        .onFailure { error in
                            // Try to load from cache
                            loadLocalFullImage()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("By \(image.author)")
                        .font(.headline)
                    
                    Text("ID: \(image.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.isImageCached(image.id) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Available offline")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .navigationTitle("Image Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveImageToPhotos()
                }) {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .alert("Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Image saved to Photos")
        }
        .onAppear {
            loadLocalFullImage()
        }
    }
    
    private func loadLocalFullImage() {
        if let localURL = viewModel.getLocalImageURL(image.id),
           let imageData = try? Data(contentsOf: localURL),
           let uiImage = UIImage(data: imageData) {
            self.localFullImage = uiImage
        }
    }
    
    private func saveImageToPhotos() {
        // Get image from cache or current view
        var imageToSave: UIImage?
        
        if let localFullImage = localFullImage {
            imageToSave = localFullImage
        } else if let url = URL(string: image.imageURL),
                  let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data) {
            imageToSave = uiImage
        }
        
        guard let imageToSave = imageToSave else { return }
        
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        showSaveSuccess = true
    }
}

#Preview {
    GalleryView()
}
