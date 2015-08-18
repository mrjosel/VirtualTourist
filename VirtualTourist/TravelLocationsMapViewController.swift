//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/11/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {
    
    //Map View
    @IBOutlet weak var mapView: MKMapView!
    
    //gesture for dropping pin
    var pinDropGesture : UILongPressGestureRecognizer?
    
    //annotations array
    var annotations = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //make vc mapView delegate
        self.mapView.delegate = self
        
        //set up pinDrop mechanism, make vc delegate
        self.pinDropGesture = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        self.mapView.addGestureRecognizer(self.pinDropGesture!)
        
    }
    
    //create view for annotations
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        //reuseID and pinView
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    
    func dropPin(sender: UIGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Ended || sender.state == UIGestureRecognizerState.Changed {
            return
        } else {
            //create coordinate object point object
            let point = sender.locationInView(self.mapView)
            let coordinates = self.mapView.convertPoint(point, toCoordinateFromView: self.mapView)
            
            //create annotation
            var dropPin = MKPointAnnotation()
            dropPin.coordinate = coordinates
            
            //apend to array
            self.annotations.append(dropPin)
            
            //add to mapview
            self.mapView.addAnnotation(dropPin)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

