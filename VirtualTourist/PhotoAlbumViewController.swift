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
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    
    //variables
    var selectedPin: MKAnnotationView!
    
    //temp var for URLstrings
    var photoURLs: [String]?
    
    //page and per_page variables
    var page = 1
    var perPage = 20
    var maxPages: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //show navBar
        self.navigationController?.navigationBar.hidden = false
        
        //setup collectionView and label
        self.photoCollectionView.backgroundColor = UIColor.whiteColor()
        self.noPhotosLabel.hidden = true
        
        //setup mapview
        self.mapView.delegate = self
        self.mapView.addAnnotation(selectedPin.annotation)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        let mapWindow = MKCoordinateRegionMakeWithDistance(self.selectedPin.annotation.coordinate, 50000, 50000)
        self.mapView.setRegion(mapWindow, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //get photos using pin cooridinate
    func getPhotos(pin: MKAnnotationView) {
        //pass pin into FlickrClient
        FlickrClient.sharedInstance().getPhotoURLs(pin, page: self.page, per_page: self.perPage) { success, result, error in
            if !success {
                //TODO: Make Alert function
            } else {
                //retrieved photoURLs
                self.photoURLs = result!
            }
        }

        


        
        //increment page in case newCollectionButton is pressed, roll back to page 1 if maxPage is reached
        if page < maxPages {
            page++
        } else {
            page = 1
        }
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
