//
//  PhotoStore.swift
//  PhotoViewDataStore
//
//  Created by Tianbo Qiu on 1/1/23.
//

import UIKit
import CoreData

enum PhotoError: Error {
    case imageCreationError
    case missingImageURL
}

class PhotoStore {
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PhotoViewDataStore")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error setting up Core Data \(error).")
            }
        }
        return container
    }()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    // Fetch intereting photos and update local persistent photo models
    func fetchInterestingPhtotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            var result = self.processPhotosResponse(data: data, error: error)
            
            if case .success = result {
                // save photos locally
                do {
                    try self.persistentContainer.viewContext.save()
                } catch {
                    result = .failure(error)
                }
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    // Process the response data from the interesting photos API
    private func processPhotosResponse(data: Data?, error: Error?) -> Result<[Photo], Error> {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        let context = persistentContainer.viewContext // main thread
        
        switch FlickrAPI.photos(fromJSON: jsonData) {
        case let.success(flickrPhotos):
            let photos = flickrPhotos.map { flickrPhoto -> Photo in
                
                // check if we already have one saved locally
                let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(flickrPhoto.photoID)")
                fetchRequest.predicate = predicate
                
                var fetchedPhotos: [Photo]?
                context.performAndWait {
                    fetchedPhotos = try? fetchRequest.execute()
                }
                
                if let existingPhoto = fetchedPhotos?.first {
                    return existingPhoto
                }
                
                // create a new Photo model otherwise
                var photo: Photo!
                context.performAndWait {
                    photo = Photo(context: context)
                    photo.title = flickrPhoto.title
                    photo.photoID = flickrPhoto.photoID
                    photo.remoteURL = flickrPhoto.remoteURL
                    photo.dateTaken = flickrPhoto.dateTaken
                }
                return photo
            }
            return .success(photos)
        case let .failure(error):
            return .failure(error)
        }
    }
}
