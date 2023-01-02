//
//  TagDataSource.swift
//  PhotoViewDataStore
//
//  Created by Tianbo Qiu on 1/2/23.
//

import UIKit
import CoreData

class TagDataSource: NSObject, UITableViewDataSource {
    
    var tags = [Tag]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        let tag = tags[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = tag.name
        cell.contentConfiguration = content
        
        return cell
    }
}
