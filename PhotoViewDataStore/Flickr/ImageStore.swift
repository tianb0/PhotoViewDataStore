//
//  ImageStore.swift
//  PhotoViewDataStore
//
//  Created by Tianbo Qiu on 1/1/23.
//

import UIKit

class ImageStore {
    
    let cache = NSCache<NSString, UIImage>()
    
    // Update in-memory cache and save image in filesystem
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
        
        let url = imageURL(forKey: key)
        if let data = image.jpegData(compressionQuality: 0.5) {
            try? data.write(to: url)
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        if let image = cache.object(forKey: key as NSString) {
            // return from cache
            return image
        }
        
        let url = imageURL(forKey: key)
        
        if let image = UIImage(contentsOfFile: url.path) {
            // return from filesystem and update the in-memory cache
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    func deleteImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        
        let url = imageURL(forKey: key)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Error removing the image from the disk: \(error)")
        }
    }
    
    // Returns the location to save the image
    func imageURL(forKey key: String) -> URL {
        let dirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = dirs.first!
        return dir.appending(path: key)
    }
}
