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
    //pin object assocoated with flickrPhoto object
    @NSManaged var pin: Pin?
    
    //title, used for naming persisted photo in memory
    @NSManaged var title: String
    
    //the following are used to construct the URL for the image
    @NSManaged var farmID: NSNumber //casting to int works here, why not elsewhere?
    @NSManaged var serverID: String
    @NSManaged var photoID: String
    @NSManaged var secret: String
    
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
        self.farmID = dictionary[FlickrClient.Response.FARM] as! Int
        self.serverID = dictionary[FlickrClient.Response.SERVER] as! String
        self.photoID = dictionary[FlickrClient.Response.ID] as! String
        self.secret = dictionary[FlickrClient.Response.SECRET] as! String
        
    }
    
    //valid url for the actual photo, using above params
    var urlString: String? {
        get {
            return "https://farm\(self.farmID).staticflickr.com/\(self.serverID)/\(self.photoID)_\(self.secret)_m.jpg"
        }
    }
    
    //actual image from flickr
    var flickrImage : UIImage? {
        
        get {
            println("flickrImage requested")
            //TODO:  NEED TO IMEPLEMENT IN IMAGE CACHING
//            return FlickrClient.sharedInstance().imageFromURLstring(self.urlString)
            return FlickrClient.Caches.imageCache.imageFromURLString(self.urlString)
            
        }
        
        set {
            //TODO: NEED SET IMAGE METHOD
        }
    }
}