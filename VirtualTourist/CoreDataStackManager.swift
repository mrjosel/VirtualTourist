//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/18/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_FILE_NAME = "VirtualTourist.sqlite"

//class to manage all CoreData actions
class CoreDataStackManager {
    
    //documents directory
    lazy var applicationsDirectory: NSURL = {
        //get array of urls matching docments directory
        let urls = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        
        //return first item in array
        return urls[urls.count - 1] as NSURL
        }()
    
    //managed object model
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        //get url of PinModel file
        let modelURL = NSBundle.mainBundle().URLForResource("PinModel", withExtension: ".momd")!
        
        //return managed object model from URL
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    //persistent store coordinator, return value optional since it could fail to be created
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        //coordinator made from managed object model
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        //full url of sqlite file
        let url = self.applicationsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME) as NSURL
        
        //error in case persistentCore fails to be created
        var error: NSError? = nil
        
        //attempt to add persistent store
        do {
            try coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch var error1 as NSError {
            error = error1
            //attempt failed, set cooridnator to nil and make NSError
            coordinator = nil
            
            //create error dict
            var dict = [NSObject : AnyObject]()//NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "persistentStoreCoordinator", code: 999, userInfo: dict as [NSObject : AnyObject])
            
            //report error and abort
            NSLog("Unresolved error \(error), \(error!.localizedDescription)")
            abort()
            
        } catch {
            fatalError()
        }
        return coordinator
        }()
    
    //managed object context
    lazy var managedObjectContext: NSManagedObjectContext? = {
        
        //create persistent store coordinator
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        
        //managed object context object
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType) //NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    func saveContext() {
        print("saving context")
        
        //check for changes
        if self.managedObjectContext!.hasChanges {
            do {
                //changes exist, try to save
                try managedObjectContext!.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    //singleton
    class func sharedInstance() -> CoreDataStackManager {
        struct Singleton {
            static var sharedInstance = CoreDataStackManager()
        }
        return Singleton.sharedInstance
    }
}