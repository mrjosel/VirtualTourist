//
//  Pin.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/19/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)

//class to persist annotations
class Pin: NSManagedObject, MKAnnotation {
    
    //managed variables
    @NSManaged var latitude: NSNumber!
    @NSManaged var longitude: NSNumber!
    @NSManaged var flickrPhotos: [FlickrPhoto]
    @NSManaged var pages: NSNumber?
    @NSManaged var page: NSNumber?
    
    //called in init
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //initializer
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext){
        //entitiy for use in CoreData Model
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        
        //super class init
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        //set parameters, convert to NSNumbers to allow for an MSMangedObject
        self.latitude = NSNumber(double: latitude)
        self.longitude = NSNumber(double: longitude)
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude as! Double, longitude: self.longitude as! Double)
    }
}