//
//  DataController.swift
//  VirtualTourist
//
//  Created by Lorrayne Paraiso  on 21/10/18.
//  Copyright © 2018 Lorrayne Paraiso. All rights reserved.
//

import Foundation
import CoreData

// This class has the following function:
// - create an instance of the NSPersistentContainer
// - provide easy access to the ManagedObjectContext
// - load the DB
// - provide any usefull method that simplify the data layer management

class DataController {
    
    let persistentContainer: NSPersistentContainer?
    
    init(dataModel: String) {
        persistentContainer = NSPersistentContainer(name: dataModel)
    }
    
    var context: NSManagedObjectContext {
        return (persistentContainer?.viewContext)!
    }
    
    func loadDb(completion: @escaping (String) -> ()) {
        persistentContainer?.loadPersistentStores(completionHandler: {description, error in
            
            guard error == nil else {
                let err = error?.localizedDescription ?? "Cannot load DB"
                completion(err)
                fatalError(err)
                
            }
            
        } )
    }
    
    func saveDB(context: NSManagedObjectContext){
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved")
            } catch {
                print("Can't save context")
            }
        }
    }
    
}

