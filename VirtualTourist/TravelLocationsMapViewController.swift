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

    //shared context
    lazy var sharedContext: NSManagedObjectContext = {

        //return context from CoreData
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()

    //fetched results controller for persisting pins
    lazy var fetchedResultsController: NSFetchedResultsController = {

        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]

        //create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController
        }()

    override func viewWillAppear(animated: Bool) {
        //always hide navBar
        self.navigationController?.navigationBar.hidden = true

        //super
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        //set up pinDrop mechanism, make vc delegate
        self.pinDropGesture = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        self.mapView.addGestureRecognizer(self.pinDropGesture!)

        //set delegates
        self.mapView.delegate = self
        self.fetchedResultsController.delegate = self

        //perform fetch
        self.fetchedResultsController.performFetch(nil)

        //add annotations from fetchedResultsController
        self.mapView.addAnnotations(self.fetchedResultsController.fetchedObjects as! [Pin])
    }

    //add pin to array and to map
    func dropPin(sender: UIGestureRecognizer) {

        //create coordinate object point object
        let point = sender.locationInView(self.mapView)
        let coordinates = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)

        //only allow pins to be dropped once, not checking state place pins indefinitely
        if sender.state == .Began {

            //create Pin object
            let pin = Pin(latitude: coordinates.latitude as Double, longitude: coordinates.longitude as Double, context: self.sharedContext)
            println(pin)

            //save context
            CoreDataStackManager.sharedInstance().saveContext()
            println("pin dropped")
        }
    }

    //method to locate Pin associated with MKAnnotationView
    func findPersistedPin(coord: CLLocationCoordinate2D) -> Pin? {
        //get lat and lon from coord
        let testLat = coord.latitude
        let testLon = coord.longitude

        //cycle through all fetchedResults
        for object in self.fetchedResultsController.fetchedObjects! {
            //get lat and lon from Pin object
            let pin = object as! Pin
            var lat = pin.latitude
            var lon = pin.longitude

            //coords match, pin object is found
            if testLat == lat && testLon == lon {
                return pin
            }
        }
        //return nil if no Pin is found
        return nil
    }

    //create view for annotations
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        //TODO: FIX RADIUS BUG
        println("viewForAnnotation")
        //reuseID and pinView
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        let gesture = mapView.gestureRecognizers![0] as! UILongPressGestureRecognizer
        //if no pinView, then create one
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.animatesDrop = true
            pinView!.draggable = false

        } else {
            //otherwise, add annotation
            pinView!.annotation = annotation
        }

        return pinView
    }

    //perform the following when pin is selected
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        println("selected annotation")
        //find Pin object matching selected annotationView
        var pin = self.findPersistedPin(view.annotation.coordinate)
        println(pin)

        //deselect pin
        mapView.deselectAnnotation(view.annotation, animated: false)
        //segue to photoAlbumVC
        self.performSegueWithIdentifier("photoAlbumVCSegue", sender: pin)
    }

    //preparing segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println("preparing segue")
        //prepare segue, get VC and pass coordinate
        if segue.identifier == "photoAlbumVCSegue" {

            //cast sender as MKAnnotationView, get coordinate from sender
            let selectedPin = sender as! Pin

            let photoAlbumVC = segue.destinationViewController as! PhotoAlbumViewController
            photoAlbumVC.selectedPin = selectedPin
        }

        //super
        super.prepareForSegue(segue, sender: sender)
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        //create annotation from anObject
        let pin = anObject as! Pin

        //check which type
        switch type {
            //insert - add pin to map
        case NSFetchedResultsChangeType.Insert:
            println("didChangeObject - Insert")
            self.mapView.addAnnotation(pin)

            //delete - remove pin from map
        case NSFetchedResultsChangeType.Delete:
            println("didChangeObject - Delete")
            self.mapView.removeAnnotation(pin)

            //update - remove pin from map, add it back in
        case NSFetchedResultsChangeType.Update:
            println("didChangeObject - Update")
            self.mapView.removeAnnotation(pin)
            self.mapView.addAnnotation(pin)

            //default - break
        default:
            break
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
