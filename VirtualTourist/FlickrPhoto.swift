//
//  FlickrPhoto.swift
//  VirtualTourist
//
//  Created by Brian Josel on 9/14/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(FlickrPhoto)

//class for persisting photos
class FlickrPhoto: NSManagedObject {
    
    //managed variables
    //title used for sort descriptor
    @NSManaged var title: String?
    
    //pin object assocoated with flickrPhoto object
    @NSManaged var pin: Pin?
    
    //the following are used to construct the URL for the image
    @NSManaged var farmID: NSNumber? //casting to int works here, why not elsewhere?
    @NSManaged var serverID: String?
    @NSManaged var photoID: String?
    @NSManaged var secret: String?
    
    //called in init
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //initializer
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        //create entity
        let entity = NSEntityDescription.entityForName("FlickrPhoto", inManagedObjectContext: context)
        
        //call super method
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //set above params, if they exist
        self.title = dictionary[FlickrClient.Response.TITLE] as? String
        self.farmID = dictionary[FlickrClient.Response.FARM] as? Int
        self.serverID = dictionary[FlickrClient.Response.SERVER] as? String
        self.photoID = dictionary[FlickrClient.Response.ID] as? String
        self.secret = dictionary[FlickrClient.Response.SECRET] as? String
        
    }
    
    //valid url for the actual photo, using above params
    var urlString: String? {
        get {
            if let farmID = self.farmID {
                if let serverID = self.serverID {
                    if let photoID = self.photoID {
                        if let secret = self.secret {
                            return "https://farm\(farmID).staticflickr.com/\(serverID)/\(photoID)_\(secret)_m.jpg"
                        }
                    }
                }
            }
            return nil
        }
    }
    
    //image file name for persisting image
    var flickrImageFileName: String? {
        get {
            if let farmID = self.farmID {
                if let serverID = self.serverID {
                    if let photoID = self.photoID {
                        if let secret = self.secret {
                            return "\(farmID)\(serverID)\(photoID)\(secret).jpg"
                        }
                    }
                }
            }
            return nil
        }
    }
    
    //actual image from flickr
    var flickrImage : UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithPhotoID(self.flickrImageFileName)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withPhotoID: self.flickrImageFileName!)
        }
    }
}