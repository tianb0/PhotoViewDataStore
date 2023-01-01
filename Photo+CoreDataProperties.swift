//
//  Photo+CoreDataProperties.swift
//  PhotoViewDataStore
//  Generated from Editor -> Create NSManagedObject subclass
//
//  Created by Tianbo Qiu on 1/1/23.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var dateTaken: Date?
    @NSManaged public var photoID: String?
    @NSManaged public var remoteURL: String?
    @NSManaged public var title: String?

}

extension Photo : Identifiable {

}
