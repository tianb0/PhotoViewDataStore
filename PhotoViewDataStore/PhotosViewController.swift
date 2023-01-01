//
//  ViewController.swift
//  PhotoViewDataStore
//
//  Created by Tianbo Qiu on 1/1/23.
//

import UIKit

class PhotosViewController: UIViewController {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var store: PhotoStore!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        store.fetchInterestingPhtotos { result in
            print(result)
        }
    }


}

