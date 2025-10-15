//
//  WallpaperImage.swift
//  SamplTestApp
//
//  Created by mac2 on 15/10/25.
//


// Models
import Foundation
internal import CoreData
import Combine
struct WallpaperImage: Identifiable {
    let id: String
    let imageURL: String
    let thumbnailURL: String
    let author: String
    
    init(id: String, imageURL: String, thumbnailURL: String, author: String) {
        self.id = id
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.author = author
    }
    
    init(from entity: ImageEntity) {
        self.id = entity.id ?? UUID().uuidString
        self.imageURL = entity.imageURL ?? ""
        self.thumbnailURL = entity.thumnailURl ?? ""
        self.author = entity.author ?? "Unknown"
    }
}
