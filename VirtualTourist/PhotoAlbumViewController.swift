//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/11/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {

    //outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    
    //variables
    var selectedPin: MKAnnotationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //show navBar
        self.navigationController?.navigationBar.hidden = false
        
        //setup mapview
        self.mapView.delegate = self
        self.mapView.addAnnotation(selectedPin.annotation)
        self.mapView.zoomEnabled = true
        let mapWindow = MKCoordinateRegionMakeWithDistance(self.selectedPin.annotation.coordinate, 50000, 50000)
        self.mapView.setRegion(mapWindow, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
