//
//  PhotoGalleryViewModel.swift
//  VirtualTourist
//
//  Created by Lorrayne Paraiso  on 21/10/18.
//  Copyright © 2018 Lorrayne Paraiso. All rights reserved.
//

import Foundation
import MapKit
import CoreData

protocol PhotoGalleryDelegate: class {
    func updateGallery(photo: Gallery)
    func updateGalleryFromDB(photo: [Photo])
    func cleanGallery()
    func updateTitle(title: String)
}

class PhotoGalleryViewModel {

    let dataController: DataController
    let coordinates: CLLocationCoordinate2D
    var pin: Pin!
    weak var delegate: PhotoGalleryDelegate?
    
    init(dataController: DataController, coordinates: CLLocationCoordinate2D) {
        self.dataController = dataController
        self.coordinates = coordinates
    }
    
    func getPhotoUrls(page: Int) {
        pin = fetchPin(coordinates)
        // check if there are stored photos for the pin
        if let photos = fetchPhoto(pin), photos.count > 0 {
            delegate?.updateGalleryFromDB(photo: photos)
        } else {
            let client = Client()
            var urlComponents = URLComponents(string: Constants.Client.baseUrl)
            //urlComponents.host = Constants.Client.baseUrl
            var queryItemsArray = [URLQueryItem]()
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.APIKey, value: Constants.FlickrParameterValues.APIKey))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.Longitude, value: String(coordinates.longitude)))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.Latitude, value: String(coordinates.latitude)))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.Radius, value: Constants.FlickrParameterValues.Radius))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.Format, value: Constants.FlickrParameterValues.Format))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.Method, value: Constants.FlickrParameterValues.Method))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.Extras, value: Constants.FlickrParameterValues.Extras))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.SafeSearch, value: Constants.FlickrParameterKeys.SafeSearch))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.Page, value: String(page)))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.PhotoPerPage, value:Constants.FlickrParameterValues.PhotoPerPage ))
            queryItemsArray.append(URLQueryItem(name: Constants.FlickrParameterKeys.NoJSONCallback, value: Constants.FlickrParameterValues.NoJSONCallback))
            urlComponents?.queryItems = queryItemsArray
            
            guard let url = urlComponents?.url else {
                print("Error in url")
                return
            }
            client.fetchRemoteData(request: url, dataHandler: .dataListHandler, completion: { listData, errorData  in
                
                if let error = errorData {
                    print("Error: ", error.errorTitle)
                    return
                }
                
                guard let listData = listData as? Flickr else {
                    print("error")
                    return
                }
                
                // If there are no more photos, reset the page to 1
                if listData.photos.photo.count == 0 {
                    self.pin.currentPage = 1
                }
                self.delegate?.updateGallery(photo: listData.photos)
            })
        }
    }
    
    func fetchImage(url: String, completion: @escaping (Data?) -> () ) {
        let client = Client()
        guard let url = URL(string: url) else {
            print("Invalid url")
            return
        }
        client.fetchRemoteData(request: url, dataHandler: .dataHandler) { data, error in
            
            guard error == nil else {
                print("Error")
                return
            }
            
            guard let data = data as? Data else {
                print("Error")
                return
            }
            
            self.addPhoto(url: url.absoluteString, data: data)
            completion(data)
        }
    }
    
    func lookUpCurrentLocation() {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if error == nil {
                if let firstLocation = placemarks?[0] {
                    self.delegate?.updateTitle(title: firstLocation.locality ?? "Unknown location")
                }
            }
            else {
                self.delegate?.updateTitle(title: "Unknown location")
            }
        })
    }
    
    func fetchPin(_ coordinates: CLLocationCoordinate2D) -> Pin? {
        let longitude = coordinates.longitude
        let latitude = coordinates.latitude
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "longitude == %lf && latitude == %lf", longitude, latitude)
        fetchRequest.predicate = predicate
        if let result = try? dataController.context.fetch(fetchRequest){
            if result.count > 0 {
                return result[0]
            }
        }
        return nil
    }
    
    func fetchPhoto(_ pin: Pin) -> [Photo]? {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        if let result = try? dataController.context.fetch(fetchRequest){
            return result
        }
        return nil
    }
    
    func addPhoto(url: String, data: Data) {
        let photo = Photo(context: dataController.context)
        photo.payload = data
        photo.url = url
        photo.pin = pin
        dataController.saveDB(context: dataController.context)
    }
    func deletePhoto(photo: Photo){
        dataController.context.delete(photo)
    }
    
    func loadNewGallery() {
        // First remove all the photo for the pin
        if let photos = fetchPhoto(pin) {
            for photo in photos {
                deletePhoto(photo: photo)
            }
        }
        dataController.saveDB(context: dataController.context)
        delegate?.cleanGallery()
        pin.currentPage += Int32(1)
        print("current page: ", pin.currentPage)
        getPhotoUrls(page: Int(pin.currentPage))
    }
    
    func removePhotos(list: [IndexPath:String]) {
        print("removed from db")
        let arrayOfUrl = Array(list.values)
        var photoToDelete = [Photo]()
        if let photo = fetchPhoto(pin){
            for elem in photo {
                if let _ = arrayOfUrl.index(of: elem.url!) {
                    print(elem.url!)
                    photoToDelete.append(elem)
                }
            }
        }
        
        for photo in photoToDelete {
            dataController.context.delete(photo)
        }
        
        dataController.saveDB(context: dataController.context)
    }
}

