//
//  FlickrPhoto.swift
//  PhotoViewDataStore
//  Decodable from JSON data
//
//  Created by Tianbo Qiu on 1/1/23.
//

import Foundation

class FlickrPhoto: Codable {
    let title: String
    let remoteURL: String?
    let photoID: String
    let dateTaken: Date
    
    enum CodingKeys: String, CodingKey {
        case title
        case remoteURL = "url_z"
        case photoID = "id"
        case dateTaken = "datetaken"
    }
}

extension FlickrPhoto: Equatable {
    static func == (lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
        return lhs.photoID == rhs.photoID
    }
}
