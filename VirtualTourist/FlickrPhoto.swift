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
    @NSManaged var urlString: String!
    @NSManaged var pin: Pin?

    //called in init
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //initializer
    init(urlString: String, context: NSManagedObjectContext) {
        
        //create entity
        let entity = NSEntityDescription.entityForName("FlickrPhoto", inManagedObjectContext: context)
        
        //call super method
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //set parameters
        self.urlString = urlString
    }
}