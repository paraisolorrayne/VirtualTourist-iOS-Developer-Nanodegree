//
//  ImageCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Lorrayne Paraiso  on 21/10/18.
//  Copyright © 2018 Lorrayne Paraiso. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    // MARK: IBOutlet
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: Properties
    var url: String!
    
    func setImageFrom(imageData: Data) {
        imageView.image = UIImage(data: imageData)
    }
    
    func startActivity() {
        activityIndicator.startAnimating()
    }
    
    func stopActivity() {
        activityIndicator.stopAnimating()
    }
    
    func resetCellImage() {
        imageView.image = nil
    }
    
    func setSelected() {
        imageView.alpha = self.imageView.alpha == 0.5 ? 1.0 : 0.5
    }
    
}
