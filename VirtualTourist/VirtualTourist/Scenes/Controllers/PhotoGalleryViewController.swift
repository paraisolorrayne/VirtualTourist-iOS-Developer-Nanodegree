//
//  PhotoGalleryViewController.swift
//  VirtualTourist
//
//  Created by Lorrayne Paraiso  on 21/10/18.
//  Copyright © 2018 Lorrayne Paraiso. All rights reserved.
//

import UIKit
import MapKit

class PhotoGalleryViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak var deletePhotos: UIBarButtonItem!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!

    // MARK: Properties
    var collectionSize = 0
    var gallery: [PhotoF]?
    var photoGallery = [Int:Photo]()
    var selectedCells = [IndexPath : String]()
    var pinCoordinates: CLLocationCoordinate2D?
    var dataController: DataController!
    var photoCache = [Int:Data]()
    var viewModel: PhotoGalleryViewModel?

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        deletePhotos.isEnabled = false
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        setupCoordinates()
        setFlowLayout()
    }

    private func setupCoordinates() {
        if let coordinates = pinCoordinates {
            viewModel = PhotoGalleryViewModel(dataController: dataController, coordinates: coordinates)
            viewModel?.delegate = self
            viewModel?.getPhotoUrls(page: 0)
            viewModel?.lookUpCurrentLocation()
        }
    }

    private func setFlowLayout(){
        let space: CGFloat = 5
        let viewWidth = view.frame.size.width
        let width = (viewWidth - 25)/3
        let height = width
        
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }

    // MARK: IBActions
    @IBAction func newGallery(_ sender: Any) {
        deletePhotos.isEnabled = false
        selectedCells.removeAll()
        photoCache.removeAll()
        viewModel?.loadNewGallery()
    }

    @IBAction func trashPhotos(_ sender: Any) {
        // remove from db the selected cells
        
        viewModel?.removePhotos(list: selectedCells)
        
        // remove from the collection view displayed
        collectionSize -= selectedCells.count
        collectionView.deleteItems(at: Array(selectedCells.keys))
        for index in selectedCells {
            photoGallery.removeValue(forKey: index.key.row)
            photoCache.removeValue(forKey: index.key.row)
        }
        selectedCells.removeAll()
        deletePhotos.isEnabled = false

    }
}

// MARK: Extension
extension PhotoGalleryViewController: PhotoGalleryDelegate {
    func updateGallery(photo: Gallery) {
        gallery = photo.photo
        DispatchQueue.main.async {
            if self.gallery?.count == 0 {
                self.locationTitle.text = "No photos available"
            }else {
                self.collectionSize = (self.gallery?.count)!
                self.collectionView.reloadData()
            }
        }
    }
    
    func updateGalleryFromDB(photo: [Photo]) {
        
        for (i, val) in photo.enumerated() {
            photoGallery[i] = val
        }
        DispatchQueue.main.async {
            self.collectionSize = self.photoGallery.count
            self.collectionView.reloadData()
        }
    }
    
    func updateTitle(title: String) {
        DispatchQueue.main.async {
            self.locationTitle.text = title
        }
    }
    
    func cleanGallery(){
        DispatchQueue.main.async {
            self.collectionSize = 0
            self.photoGallery.removeAll()
            self.photoCache.removeAll()
            self.gallery = nil
            self.collectionView.reloadData()
        }
    }
    
}

// MARK: Error Delegate
extension PhotoGalleryViewController: ErrorControllerProtocol {
    func dismissActivityControl() {
        
    }
    
    func presentError(alertController: UIAlertController) {
        present(alertController, animated: true)
    }
    
    func fetchData() {
        
    }
    
}

// MARK: Collection view delegate
extension PhotoGalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionSize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if deletePhotos.isEnabled == false {
            cell.imageView.alpha = 1.0
        }
        
        cell.activityIndicator.hidesWhenStopped = true
        if  photoGallery.count > 0 {
            if let data = photoGallery[indexPath.row], let payload = data.payload {
                cell.setImageFrom(imageData: payload)
                cell.url = data.url
            }
        } else {
            if let cache = photoCache[indexPath.row] {
                cell.setImageFrom(imageData: cache)
            } else {
                cell.resetCellImage()
                cell.stopActivity()
                cell.startActivity()
                cell.url = gallery![indexPath.row].url_m
                self.viewModel?.fetchImage(url: gallery![indexPath.row].url_m) { data in
                    
                    guard let data = data else {
                        return
                    }
                    self.photoCache[indexPath.row] = data
                    DispatchQueue.main.async {
                        cell.stopActivity()
                        cell.setImageFrom(imageData: data)
                    }
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
        cell.setSelected()
        if let _ = selectedCells[indexPath] {
            selectedCells.removeValue(forKey: indexPath)
        } else {
            selectedCells[indexPath] = cell.url
        }
        deletePhotos.isEnabled = (selectedCells.count > 0) ? true : false
    }
    
}

extension PhotoGalleryViewController {
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }
}

extension PhotoGalleryViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location) else { return nil }
        
        guard let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        
        guard let detailVC = storyboard?.instantiateViewController(withIdentifier: "PhotoDetailViewController") as? PhotoDetailViewController else { return nil }
        performSegue(withIdentifier: "PhotoDetailViewController", sender: self)
        let photo = photoCache[indexPath.row]
        detailVC.photo = photo
        
        detailVC.preferredContentSize = CGSize(width: 0.0, height: 300)
        
        previewingContext.sourceRect = cell.frame
        
        return detailVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
    }
    

}
