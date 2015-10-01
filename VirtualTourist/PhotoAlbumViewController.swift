//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/11/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate ,UICollectionViewDelegate, UICollectionViewDataSource {

    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    //variables
    var selectedPin: Pin!//MKAnnotationView!
    
    //shared context
    lazy var sharedContext: NSManagedObjectContext = {
        
        //return context from CoreData
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    //fetched results controller for persisting pins
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "FlickrPhoto")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "urlString", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin);
        
        //create controller from fetch request
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        }()
    
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
        self.mapView.addAnnotation(selectedPin)//.annotation)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        let mapWindow = MKCoordinateRegionMakeWithDistance(self.selectedPin.coordinate, 50000, 50000)
        self.mapView.setRegion(mapWindow, animated: true)
        
        //show or hide photoCollectionView and noPhotosLabel based on number of photos present
        self.showHidePhotosLabel()
        
        //perform fetch
        self.fetchedResultsController.delegate = self
        self.fetchedResultsController.performFetch(nil)
        
        println(selectedPin)
        
        //get photos if no photos persisted with Pin
        if self.selectedPin.flickrPhotos.isEmpty {
            println("no photos persisted, getting photos")
            self.getPhotos(selectedPin, page: selectedPin.page as? Int, perPage: FlickrClient.sharedInstance().perPage) { success, error in
                
                //create gettingPhotosAlert
//                var gettingPhotosAlert = self.showGettingPhotosAlert()
                
                //perform segue if successful
                if success {
                    println("segueing to next VC")
                    dispatch_async(dispatch_get_main_queue(), {
//                        gettingPhotosAlert.dismissViewControllerAnimated(true, completion: {
                            //reload photos
                            println("selectedPin.flickrPhotos = \(self.selectedPin.flickrPhotos.count)")
//                        })
                    })
                } else {
                    //alert user to error
                    println("failed to get all photos")
                    dispatch_async(dispatch_get_main_queue(), {
//                        gettingPhotosAlert.dismissViewControllerAnimated(true, completion: {
                            self.makeAlert(self, title: "Error", error: error)
                        })
//                    })
                }
            }
        } else {
            println("persisted photos present")
        }
    }
    
    //gets size for collectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedPin.flickrPhotos.count //FlickrClient.sharedInstance().photoURLs.count
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
        if (self.selectedPin.page as! Int) < (self.selectedPin.pages as! Int) {
            self.selectedPin.page = NSNumber(int: (self.selectedPin.page as! Int) + 1)
        } else {
            self.selectedPin.page = NSNumber(int: 1)
        }
        
        //begin alertView while retrieving photos
        var gettingPhotosAlert = self.showGettingPhotosAlert()
        
        //get photos, overwrites existing collection
        self.getPhotos(self.selectedPin, page: self.selectedPin.page as? Int, perPage: FlickrClient.sharedInstance().perPage) { success, error in
            
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
    
    //create flickrPhoto objects from urlStrings
    func makeFlickrPhotos(urlStrings: [String]) /*-> [FlickrPhoto]*/ {
        println("making flickrPhoto objects")

        //map returned urlStrings into flickrPhoto objects
        var flickrPhotos = urlStrings.map() { (urlString: String) -> FlickrPhoto in
            
            //create flickrPhoto and set pin param as selectedPin
            let flickrPhoto = FlickrPhoto(urlString: urlString, context: self.sharedContext)
            flickrPhoto.pin = self.selectedPin
            
            return flickrPhoto
        }
        
        println("returning flickrPhotos")
    }
    
    //get photos using pin cooridinate
    func getPhotos(pin: Pin, page: Int?, perPage: Int, completionHandler: (success: Bool, error: NSError?) -> Void) {
        println("GETTING PHOTOS")
        //pass pin into FlickrClient
        FlickrClient.sharedInstance().getPhotoURLs(pin, page: page, perPage: perPage) { success, result, error in
            var error: NSError?
            if !success {
                //create error
                println("couldn't get photo urls")
                error = self.errorHandle("getPhotos", errorString: "Failed to Retrieve Photos")
            } else {
                //retrieved photoURLs
                println("got all the photos")
                error = nil
                pin.pages = result![FlickrClient.OutputData.PAGES] as! Int
                println("pin.pages = \(pin.pages)")
                var urlStrings = pin.pages == 0 ? [] : result![FlickrClient.OutputData.URLS] as! [String]
                self.makeFlickrPhotos(urlStrings)
                CoreDataStackManager.sharedInstance().saveContext()
            }
            //complete with handler
            completionHandler(success: success, error: error)
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
