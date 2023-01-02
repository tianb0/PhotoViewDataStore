//
//  PhotoStore.swift
//  PhotoViewDataStore
//  Work as a repository
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
    
    let imageStore = ImageStore()
    
    // Fetch intereting photos and update local persistent photo models
    func fetchInterestingPhtotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            self.processPhotosResponse(data: data, error: error) { result in
                completion(result)
            }
        }
        
        task.resume()
    }
    
    // Process the response data from the interesting photos API
    private func processPhotosResponse(data: Data?,
                                       error: Error?,
                                       completion: @escaping (Result<[Photo], Error>) -> Void) {
        guard let jsonData = data else {
            completion(.failure(error!))
            return
        }
        
        persistentContainer.performBackgroundTask { context in
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
                // for the insertions to persist and be available to other managed object contexts
                // we need to save the changes to the background context
                do {
                    try context.save()
                } catch {
                    print("Error saving to Core Data: \(error).")
                    completion(.failure(error))
                    return
                }
                // An NSManagedObject should only be accessed from the context that it is associated with
                
                let photoIDs = photos.map { $0.objectID }
                let viewContext = self.persistentContainer.viewContext
                let viewContextPhotos = photoIDs.map { viewContext.object(with: $0) } as! [Photo]
                completion(.success(viewContextPhotos))
            case let .failure(error):
                completion(.failure(error))
            }
        }
        
    }
    
    // Fetch all saved photo metas
    func fetchAllPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken), ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Fetch image for the photo meta.
    func fetchImage(for photo: Photo, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let photoKey = photo.photoID!
        
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        guard let photoURL = photo.remoteURL, let url = URL(string: photoURL) else {
            completion(.failure(PhotoError.missingImageURL))
            return
        }
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { data, response, error in
            let result = self.processImageResponse(data: data, error: error)
            
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        
        task.resume()
    }
    
    private func processImageResponse(data: Data?, error: Error?) -> Result<UIImage, Error> {
        guard let imageData = data, let image = UIImage(data: imageData) else {
            if data == nil {
                return .failure(error!)
            } else {
                return .failure(PhotoError.imageCreationError)
            }
        }
        
        return .success(image)
    }
    
    func fetchAllTags(completion: @escaping (Result<[Tag], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: #keyPath(Tag.name), ascending: true)
        fetchRequest.sortDescriptors = [sortByName]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
