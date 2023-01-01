//
//  ViewController.swift
//  PhotoViewDataStore
//
//  Created by Tianbo Qiu on 1/1/23.
//

import UIKit

class PhotosViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var store: PhotoStore!
    let photoDataSource = PhotoDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = photoDataSource
        
        updateDataSource() // loading existing photos (metas, as placeholders, image will be fetched later when cell is visible)
        
        store.fetchInterestingPhtotos { result in
            self.updateDataSource() // load again to add newly fetched photos (metas, as placeholders, image will be fetched later when cell is visible)
        }
    }

    // update photo data source by existing/latest photo metas and reload UI
    private func updateDataSource() {
        store.fetchAllPhotos { photosResult in
            switch photosResult {
            case let .success(photos):
                self.photoDataSource.photos = photos
            case .failure:
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    
    
    // fetch image for a photo meta only when the cell is visible
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = photoDataSource.photos[indexPath.row] // get photo meta from photoDataSource
        
        store.fetchImage(for: photo) { result in
            // the index path for the photo might have changed between the time
            // the request started and finished, so find the most recent index path
            guard let photoIndex = self.photoDataSource.photos.firstIndex(of: photo),
                  case let .success(image) = result else {
                // photo is no longer in the data source or the image fetch failed
                return
            }
            
            let photoIndexPath = IndexPath(row: photoIndex, section: 0)
            
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                cell.update(displaying: image)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showPhoto":
            if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
                let photo = photoDataSource.photos[selectedIndexPath.row] // models and view are aligned by index
                
                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = store
            }
        default:
            preconditionFailure("Unexpected segue")
        }
    }
}

