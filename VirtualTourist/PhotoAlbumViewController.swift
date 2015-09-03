//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/11/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource {

    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    //variables
    var selectedPin: MKAnnotationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //show navBar
        self.navigationController?.navigationBar.hidden = false
        
        //setup collectionView and label
        self.photoCollectionView.backgroundColor = UIColor.whiteColor()
        self.noPhotosLabel.hidden = true
        
        //set datasource
        self.photoCollectionView.dataSource = self
        
        //setup mapview
        self.mapView.delegate = self
        self.mapView.addAnnotation(selectedPin.annotation)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        let mapWindow = MKCoordinateRegionMakeWithDistance(self.selectedPin.annotation.coordinate, 50000, 50000)
        self.mapView.setRegion(mapWindow, animated: true)
        
        println("photoURLs = \(FlickrClient.sharedInstance().photoURLs)")
        
    }
    
    //gets size for collectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return FlickrClient.sharedInstance().photoURLs.count
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        //TODO: IMPLEMENT COLLECTION VIEW
    }
    
    //cell to be populated
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //create cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        //get image at url in array
        cell.cellImageView.image = UIImage(contentsOfFile: FlickrClient.sharedInstance().photoURLs[indexPath.row])
        
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //grabs new collection of photos by incrementing page
    //TODO: RANDOMIZE PAGE AND NUMBER OF PHOTOS TO GRAB
    @IBAction func newCollectionButtonPressed(sender: UIBarButtonItem) {
        
        //increment page in case newCollectionButton is pressed, roll back to page 1 if maxPage is reached
        if FlickrClient.sharedInstance().page < FlickrClient.sharedInstance().maxPages {
            FlickrClient.sharedInstance().page++
        } else {
            FlickrClient.sharedInstance().page = 1
        }
        
        //get photos, overwrites existing collection
        self.getPhotos(self.selectedPin, page: FlickrClient.sharedInstance().page, perPage: FlickrClient.sharedInstance().perPage) { success in
            
            //if success, update collection table
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    self.photoCollectionView.reloadData()
                })
            } else {
                println("failed to get new collection")
                //TODO: MAKE ALERT FUNCTION
            }
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
