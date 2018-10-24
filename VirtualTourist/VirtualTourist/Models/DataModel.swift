//
//  DataModel.swift
//  VirtualTourist
//
//  Created by Lorrayne Paraiso  on 21/10/18.
//  Copyright © 2018 Lorrayne Paraiso. All rights reserved.
//

import Foundation

// Data model for encoding/deconding json files and support data

struct ErrorData{
    let errorTitle: String
    let errorMsg: String
}


struct Flickr: Decodable {
    let photos: Gallery
}

struct Gallery: Decodable {
    let photo: [PhotoF]
}

struct PhotoF: Decodable {
    let url_m: String
}

struct PhotoObject {
    let url_m: String
    let data: Data
}
