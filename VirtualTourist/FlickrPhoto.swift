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
    @NSManaged var urlString: String?
    @NSManaged var pin: Pin?
    @NSManaged var title: String?

    //called in init
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //initializer
    init(urlString: String?, context: NSManagedObjectContext) {
        
        //create entity
        let entity = NSEntityDescription.entityForName("FlickrPhoto", inManagedObjectContext: context)
        
        //call super method
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //set parameters
        if let urlString = urlString {
            self.urlString = urlString
        }
    }
    
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