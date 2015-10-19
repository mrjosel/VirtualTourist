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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //navigation buttons
    var trashButton: UIBarButtonItem!
    
    //Selected Pin variable
    var selectedPin: Pin!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndices = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    //shared context
    lazy var sharedContext: NSManagedObjectContext = {
        
        //return context from CoreData
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    //fetched results controller for persisting pins
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //create fetch request with sort descriptor
        let fetchRequest = NSFetchRequest(entityName: "FlickrPhoto")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
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
        
        //configure viewController UI
        self.configureViewController()
        
        //perform fetch
        self.fetchedResultsController.delegate = self
        do {
            try self.fetchedResultsController.performFetch()
        } catch _ {
        }
        
        //get photos if no photos persisted with Pin
        if self.selectedPin.flickrPhotos.isEmpty {

            //get photos
            self.getPhotos()
            
        } else {
            //enable UI elements based on having photos
            self.enableUI(true, hasPhotos: true)
        }
    }
    
    //get sections for collectionView
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    //gets size for collectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //get section info
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        
        //return size of section
        return sectionInfo.numberOfObjects
    }
    
    //when cell is selected, change alpha, add index to selectedIndices
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        //get cell and flickrPhoto
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        let flickrPhoto = self.fetchedResultsController.objectAtIndexPath(indexPath) as! FlickrPhoto
        
        //add or remove cell index from selectedIndicies
        if let index = self.selectedIndices.indexOf(indexPath) {
            self.selectedIndices.removeAtIndex(index)
        } else {
            self.selectedIndices.append(indexPath)
        }
        
        //reconfigure cell
        self.configureCell(cell, withFlickrPhoto: flickrPhoto, atIndexPath: indexPath)
        
        //check if selectedIndicies is empty, if so, disable trash button
        self.trashButton.enabled = !self.selectedIndices.isEmpty
    }
    
    //cell to be populated
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //get cell and flickrPhoto
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let flickrPhoto = self.fetchedResultsController.objectAtIndexPath(indexPath) as! FlickrPhoto
        
        //configure cell
        self.configureCell(cell, withFlickrPhoto: flickrPhoto, atIndexPath: indexPath)
        
        //check if selectedIndicies is empty, if so, disable trash button
        self.trashButton.enabled = !self.selectedIndices.isEmpty
        
        return cell
    }
    
    //create three fresh arrays when controller is about to make changes
    func controllerWillChangeContent(controller: NSFetchedResultsController) {

        self.deletedIndexPaths = [NSIndexPath]()
        self.insertedIndexPaths = [NSIndexPath]()
        self.updatedIndexPaths = [NSIndexPath]()
    }

    //called when one or more photos are being added/deleted
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: NSManagedObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            //keeping track of a new photo object being added, array called back in controllerDidChangeContent
            case .Insert:
                self.insertedIndexPaths.append(newIndexPath!)
                break
            //keeping track of photo objects being deleted
            case .Delete:
                self.deletedIndexPaths.append(indexPath!)
                break
            case .Update:
            //keeping track of updated photo objects, method never expected to be called
                self.updatedIndexPaths.append(indexPath!)
            case .Move:
                //unused
                break
            default:
                break
            }
    }
    
    //perform collectionView batch updates using info from updated, deleted, inserted index arrays
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

        //perform batch update
        self.photoCollectionView.performBatchUpdates({() -> Void in
            
            //inserted photo objects
            for indexPath in self.insertedIndexPaths {
                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            //deleted photo objects
            for indexPath in self.deletedIndexPaths {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            //updated photo objects
            for indexPath in self.updatedIndexPaths {
                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureCell(cell: PhotoCollectionViewCell, withFlickrPhoto flickrPhoto: FlickrPhoto, atIndexPath indexPath: NSIndexPath) {
        
        //pending image
        var cellImage = UIImage(named: "pending-image")
        
        //check if flickrPhoto.flickrImageFileName is "" or nil, set to no-image
        if flickrPhoto.flickrImageFileName == nil || flickrPhoto.flickrImageFileName == "" {
            cellImage = UIImage(named: "no-image")
            
        //flickrImageFileName exists, check if image is attached to flickrPhoto object
        } else if flickrPhoto.flickrImage != nil {
            cellImage = flickrPhoto.flickrImage
        }
        //flickrImageFileName exists but image is not downloaded/cached/attached to flickrPhoto object
        else {
            
            //get url from flickrPhoto
            if let urlString = flickrPhoto.urlString {
                
                //use REST method to get image
                _ = FlickrClient.sharedInstance().taskForGETRequest(urlString, requestType: FlickrClient.Request.IMAGE) {success, result, error in
                    
                    //check for error
                    if let error = error {
                        //error, set image to no-image
                        print("Error: \(error.localizedDescription)")
                        cellImage = UIImage(named: "no-image")
                    } else {
                        //attempt to cast result as NSData
                        if let imgData = result as? NSData {
                            //attempt to create UIImage from casted data
                            if let img = UIImage(data: imgData) {
                                
                                //set flickrPhoto imageto cellImage
                                flickrPhoto.flickrImage = img
                                
                                //set cell's image to cellImage
                                dispatch_async(dispatch_get_main_queue(), {
                                    cell.cellImageView!.image = img
                                })
                            } else {
                                //failed to create img from casted data, set image to no-image
                                cellImage = UIImage(named: "no-image")
                            }
                        } else {
                            //failed to cast result to NSData, set image to no-image
                            cellImage = UIImage(named: "no-image")
                        }
                    }
                }
            } else {
                //failed to get flickrPhoto.urlString"
                cellImage = UIImage(named: "no-image")
            }
        }
        cell.cellImageView!.image = cellImage

        //adjust alpha if cell is selected
        if let _ = self.selectedIndices.indexOf(indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }
    }

    //grabs new collection of photos by incrementing page
    //TODO: RANDOMIZE PAGE AND NUMBER OF PHOTOS TO GRAB
    @IBAction func newCollectionButtonPressed(sender: UIBarButtonItem) {

        //increment page in case newCollectionButton is pressed, roll back to page 1 if maxPage is reached
        if (self.selectedPin.page as! Int) < (self.selectedPin.pages as! Int) {
            self.selectedPin.page = NSNumber(int: (self.selectedPin.page as! Int) + 1)
        } else {
            self.selectedPin.page = NSNumber(int: 1)
        }
        
        //remove all photos
        self.deleteAllFlickrPhotos()
        
        //get photos
        self.getPhotos()
    }
    
    //if there are indicies in the selectedIndices array, delete those photos
    func trashSelectedPhotos() {

        //flickrPhotos to delete array
        var flickrPhotosToDelete = [FlickrPhoto]()
        
        //iterate through selectedIndicies
        for indexPath in self.selectedIndices {
            flickrPhotosToDelete.append(self.fetchedResultsController.objectAtIndexPath(indexPath) as! FlickrPhoto)
        }
        
        //iterate through flickrPhotosToDelete and delete from context
        for flickrPhoto in flickrPhotosToDelete {
            self.sharedContext.deleteObject(flickrPhoto)
        }
        
        //save context
        CoreDataStackManager.sharedInstance().saveContext()
        
        //clear selectedIndicies array
        self.selectedIndices = [NSIndexPath]()
        
        //show or hide noPhotos based on size of FlickrPhotos array
        self.enableUI(true, hasPhotos: self.selectedPin.flickrPhotos.count != 0)
        
    }
    
    //remove all flickrPhotos
    func deleteAllFlickrPhotos() {
        for flickrPhoto in self.fetchedResultsController.fetchedObjects as! [FlickrPhoto] {
            self.sharedContext.deleteObject(flickrPhoto)
        }
    }
    
    //get photos using pin cooridinate
    func getPhotos() {
        
        //bool for if photos exist,
        var hasPhotos: Bool?// = false
        
        //disable UI, make activity indicator
        dispatch_async(dispatch_get_main_queue(), {
            self.enableUI(false, hasPhotos: nil)
            self.activityIndicator.startAnimating()
        })

        //pass pin into FlickrClient
        FlickrClient.sharedInstance().getPhotos(self.selectedPin, perPage: FlickrClient.sharedInstance().perPage) { success, result, error in
            //successfully retreived result
            if success {
                //set hasPhotos, check if there are photos
                hasPhotos = (Int((result![FlickrClient.Response.TOTAL] as! String)) != 0)
                if hasPhotos! {
                    //if total is non zero, pages is also non-zero, set value in pin object
                    self.selectedPin.pages = result![FlickrClient.Response.PAGES] as! Int
                    
                    //get array of dicts, each dict is a flickrPhoto object
                    if let photoDicts = result![FlickrClient.Response.PHOTO] as? [[String: AnyObject]] {
                        //parse each dict and create flickrPhoto object
                        var flickrPhoto = photoDicts.map() { (dict: [String: AnyObject]) -> FlickrPhoto in
                            let flickrPhoto = FlickrPhoto(dictionary: dict, context: self.sharedContext)
                            flickrPhoto.pin = self.selectedPin
                            return flickrPhoto
                        }
                    }
                }
            } else {
                //alert user to error
                self.makeAlert(self, title: "Error", error: error)
            }
            
            //enable UI, stop activity indicator
            dispatch_async(dispatch_get_main_queue(), {
                self.activityIndicator.stopAnimating()
                self.enableUI(true, hasPhotos: hasPhotos)
            })
        }
    }
    
    //enable/disable UI elements selectively, based on whether photos exist or not
    func enableUI(bool: Bool, hasPhotos: Bool?) {
        
        //enable/disable elements regardless of photos
        self.navigationItem.leftBarButtonItem?.enabled = bool
        
        //enable/disable, show/hide based on whether photos exist
        if let hasPhotos = hasPhotos {
            self.newCollectionButton.enabled = hasPhotos
            self.photoCollectionView.hidden = !hasPhotos
            self.noPhotosLabel.hidden = hasPhotos
        } else {
            //hasPhotos is nil, use bool
            self.newCollectionButton.enabled = bool
            self.photoCollectionView.hidden = !bool
            self.noPhotosLabel.hidden = !bool
        }
    }
    
    //all commands to configure viewController
    func configureViewController() {
        //show navBar, setup trash button
        //make rightbar buttons
        self.trashButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "trashSelectedPhotos")
        self.trashButton.enabled = false
        self.newCollectionButton.enabled = false
        
        self.navigationController?.navigationBar.hidden = false
        self.navigationItem.rightBarButtonItem = self.trashButton
        
        //activityIndicator
        self.activityIndicator.hidesWhenStopped = true
        
        //setup collectionView
        self.photoCollectionView.backgroundColor = UIColor.whiteColor()
        self.photoCollectionView.hidden = true
        
        //setup noPhotosLabel
        self.noPhotosLabel.text = "No Photos"   //TODO: MAKE TEXT PRETTY
        self.noPhotosLabel.hidden = true
        
        //set datasource
        self.photoCollectionView.dataSource = self
        self.photoCollectionView.delegate = self
        
        //setup mapview
        self.mapView.delegate = self
        self.mapView.addAnnotation(selectedPin)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        let mapWindow = MKCoordinateRegionMakeWithDistance(self.selectedPin.coordinate, 50000, 50000)
        self.mapView.setRegion(mapWindow, animated: true)
    }
    
    //alert function
    func makeAlert(hostVC: UIViewController, title: String, error: NSError?) -> Void {
        //handler for OK button depending on VC
//        let handler: ((alert: UIAlertAction!) -> (Void))?
        var messageText: String!
        
        if let error = error {
            messageText = error.localizedDescription
        } else {
            messageText = "Press OK to Continue"
        }
        
        //create UIAlertVC
        let alertVC = UIAlertController(title: title, message: messageText, preferredStyle: UIAlertControllerStyle.Alert)
        
        //create action
        let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        
        //add actions to alertVC
        alertVC.addAction(ok)
        dispatch_async(dispatch_get_main_queue(), {
            //present alertVC
            hostVC.presentViewController(alertVC, animated: true, completion: nil)
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        CoreDataStackManager.sharedInstance().saveContext()
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
