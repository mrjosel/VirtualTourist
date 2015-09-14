//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/11/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

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
        
        //reload all data
        self.photoCollectionView.reloadData()

        
        //show navBar
        self.navigationController?.navigationBar.hidden = false
        
        //setup collectionView
        self.photoCollectionView.backgroundColor = UIColor.whiteColor()
        
        //set datasource
        self.photoCollectionView.dataSource = self
        self.photoCollectionView.delegate = self
        
        //setup mapview
        self.mapView.delegate = self
        self.mapView.addAnnotation(selectedPin.annotation)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        let mapWindow = MKCoordinateRegionMakeWithDistance(self.selectedPin.annotation.coordinate, 50000, 50000)
        self.mapView.setRegion(mapWindow, animated: true)
        
        //show or hide photoCollectionView and noPhotosLabel based on number of photos present
        self.showHidePhotosLabel()
    }
    
    //gets size for collectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return FlickrClient.sharedInstance().photoURLs.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //TODO: IMPLEMENT FOR PERSISTENCE
    }
    
    //cell to be populated
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //create cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        //get image from retreived URLs
        if FlickrClient.sharedInstance().photoURLs.count != 0 {
            let photoURLstring = FlickrClient.sharedInstance().photoURLs[indexPath.row]
            let photoURL = NSURL(string: photoURLstring)
            let photoData = NSData(contentsOfURL: photoURL!)
            cell.cellImageView.image = UIImage(data: photoData!)
        }
        
        return cell
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //if no photos exist, hide photoCollectionView and show noPhotosLabel
    func showHidePhotosLabel() {
        self.noPhotosLabel.text = "No Photos"
        //TODO: MAKE TEXT LOOK PRETTY
        if FlickrClient.sharedInstance().photoURLs.count == 0 {
            self.photoCollectionView.hidden = true
            self.noPhotosLabel.hidden = false
        } else {
            self.photoCollectionView.hidden = false
            self.noPhotosLabel.hidden = true
        }
    }

    //grabs new collection of photos by incrementing page
    //TODO: RANDOMIZE PAGE AND NUMBER OF PHOTOS TO GRAB
    @IBAction func newCollectionButtonPressed(sender: UIBarButtonItem) {
        
        //disable newCollectionButton
        self.newCollectionButton.enabled = false
        
        //increment page in case newCollectionButton is pressed, roll back to page 1 if maxPage is reached
        if FlickrClient.sharedInstance().page < FlickrClient.sharedInstance().maxPages {
            FlickrClient.sharedInstance().page++
        } else {
            FlickrClient.sharedInstance().page = 1
        }
        
        //begin alertView while retrieving photos
        var gettingPhotosAlert = self.showGettingPhotosAlert()
        
        //get photos, overwrites existing collection
        self.getPhotos(self.selectedPin, page: FlickrClient.sharedInstance().page, perPage: FlickrClient.sharedInstance().perPage) { success, error in
            
            //if success, update collection table
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    self.photoCollectionView.reloadData()
                })
            } else {
                //alert user
                println("failed to get new collection")
                self.makeAlert(self, title: "Error", error: error)
            }
        }
        //end alertView,enable newCollectionButton upon completion
        gettingPhotosAlert.dismissViewControllerAnimated(true, completion: {
            self.newCollectionButton.enabled = true
        })
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
