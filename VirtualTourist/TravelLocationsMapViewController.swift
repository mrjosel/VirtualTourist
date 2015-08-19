//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/11/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //Map View
    @IBOutlet weak var mapView: MKMapView!
    
    //gesture for dropping pin
    var pinDropGesture : UILongPressGestureRecognizer?
    
    //annotations array
    var annotations = [MKPointAnnotation]()
    
    //shared context
    lazy var sharedContext: NSManagedObjectContext = {
        
        //return context from CoreData
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    //fetched results controller for persisting pins
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        //create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //set delegates
        self.mapView.delegate = self
        self.fetchedResultsController.delegate = self
        
        //set up pinDrop mechanism, make vc delegate
        self.pinDropGesture = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        self.mapView.addGestureRecognizer(self.pinDropGesture!)
        
        //perform fetch
        self.fetchedResultsController.performFetch(nil)
        
        //get any persisted annotations if they exist
        self.getAnnotations()
        
    }
    
    //add pin to array and to map
    func dropPin(sender: UIGestureRecognizer) {

        //create coordinate object point object
        let point = sender.locationInView(self.mapView)
        let coordinates = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        
        //only allow pins to be dropped once, not checking state place pins indefinitely
        if sender.state == UIGestureRecognizerState.Began {
            //create annotation
            var dropPin = MKPointAnnotation()
            dropPin.coordinate = coordinates
            
            //apend to array
            self.annotations.append(dropPin)
            
            //add to mapview
            self.mapView.addAnnotation(dropPin)
        }
    }
    
    //get persisted annotations
    func getAnnotations() {

        //get array of objects from fetchResultsController
        let sectionInfo = self.fetchedResultsController.sections![0] as! NSFetchedResultsSectionInfo
        
        //TODO: WRAP FOR LOOP IN IF != 0 STATEMENT 
        if sectionInfo.numberOfObjects == 0 {
            println("no objects persisted")
            return
        }
        
        //for each persisted pin object
        for object in sectionInfo as! NSArray {
            //get persisted latitude and longitude information
            let lat = (object as! Pin).latitude as! Double
            let lon = (object as! Pin).longitude as! Double
            
            //create coordinate from lat and lon
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            //create annotation, add coordinate, add to map
            var pin = MKPointAnnotation()
            pin.coordinate = coordinate
            self.mapView.addAnnotation(pin)
        }
    }
    
    
    
    //create view for annotations
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        //TODO: FIX RADIUS BUG
        
        //reuseID and pinView
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        
        //if no pinView, then create one
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.animatesDrop = true
            pinView!.draggable = true
        } else {
            //otherwise, add annotation
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    
//    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//
//    }
//    
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        
//    }
//    
//    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
//        
//    }
//    
//    
//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

