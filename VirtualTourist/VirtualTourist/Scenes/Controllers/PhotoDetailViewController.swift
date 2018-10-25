//
//  PhotoDetailViewController.swift
//  VirtualTourist
//
//  Created by Lorrayne Paraiso  on 25/10/18.
//  Copyright © 2018 Lorrayne Paraiso. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {

    // IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    
    // Properties
    var photo: Data?
    
    // Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photo = photo {
            imageView.image = UIImage(data: photo)
        }
        
    }

}
