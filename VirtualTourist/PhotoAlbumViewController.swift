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
    
    //Selected Pin variable
    var selectedPin: Pin!
    
    //image array, get images from flickrPhoto objects and append to local array, use local array to configure images (faster this way)
    var flickrImgs = [UIImage]()
    
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
        self.fetchedResultsController.performFetch(nil)
        
        //get photos if no photos persisted with Pin
        if self.selectedPin.flickrPhotos.isEmpty {
            //get photos
            self.getPhotos({() -> Void in
            //TODO: NEED BUSY ALERT
            })
        } else {
            //show or hide photoCollectionView and noPhotosLabel based on number of photos present
            self.hideNoPhotosLabel(true)
        }
    }
    
    //get sections for collectionView
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    //gets size for collectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //get section info
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        //return size of section
        return sectionInfo.numberOfObjects
    }
    
    //when cell is selected, change alpha, add index to selectedIndices
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        //get cell and flickrPhoto
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        let flickrPhoto = self.fetchedResultsController.objectAtIndexPath(indexPath) as! FlickrPhoto
        
        //add or remove cell index from selectedIndicies
        if let index = find(self.selectedIndices, indexPath) {
            self.selectedIndices.removeAtIndex(index)
        } else {
            self.selectedIndices.append(indexPath)
        }
        
        //reconfigure cell
        self.configureCell(cell, withFlickrPhoto: flickrPhoto, atIndexPath: indexPath)
        
        //check if selectedIndicies is empty, if so, disable trash button
        self.navigationItem.rightBarButtonItem?.enabled = !self.selectedIndices.isEmpty
        
        println(flickrPhoto.urlString!)

    }
    
    //cell to be populated
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //get cell and flickrPhoto
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let flickrPhoto = self.fetchedResultsController.objectAtIndexPath(indexPath) as! FlickrPhoto
        
        //configure cell
        self.configureCell(cell, withFlickrPhoto: flickrPhoto, atIndexPath: indexPath)
        
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
        didChangeObject anObject: AnyObject,
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
            
            }, completion: {(Bool) -> Void in CoreDataStackManager.sharedInstance().saveContext()})
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureCell(cell: PhotoCollectionViewCell, withFlickrPhoto flickrPhoto: FlickrPhoto, atIndexPath indexPath: NSIndexPath) {
        
        //TODO: RECONFIGURE TO WORK WITH SESSION TASK
        
        //pending image
        var cellImage = UIImage(named: "pending-image")
        
        //check if flickrPhoto.flickrImageFileName is "" or nil, set to no-image
        if flickrPhoto.flickrImageFileName == nil || flickrPhoto.flickrImageFileName == "" {
            println("no image")
            cellImage = UIImage(named: "no-image")
            
        //flickrImageFileName exists, check if image is attached to flickrPhoto object
        } else if flickrPhoto.flickrImage != nil {
            println("loading image \(flickrPhoto.flickrImage)")
            cellImage = flickrPhoto.flickrImage
        }
        //flickrImageFileName exists but image is not downloaded/cached/attached to flickrPhoto object
        else {

            //get url from flickrPhoto
            if let urlString = flickrPhoto.urlString {
                
                //use REST method to get image
                let task = FlickrClient.sharedInstance().taskForGETRequest(urlString, requestType: FlickrClient.Request.IMAGE) {success, result, error in
                    
                    //check for error
                    if let error = error {
                        //error, set image to no-image
                        println("Error: \(error.localizedDescription)")
                        cellImage = UIImage(named: "no-image")
                    } else {
                        //attempt to cast result as NSData
                        if let imgData = result as? NSData {
                            //attempt to create UIImage from casted data
                            if let img = UIImage(data: imgData) {
                                //set cellImage to img
                                cellImage = img
                            } else {
                                //failed to create img from casted data, set image to no-image
                                println("failed to create img from casted data")
                                cellImage = UIImage(named: "no-image")
                            }
                        } else {
                            //failed to cast result to NSData, set image to no-image
                            println("failed to cast result to NSData")
                            cellImage = UIImage(named: "no-image")
                        }
                    }
                }
 
//                //make url from urlString
//                let url = NSURL(string: urlString)
//                
                //get data from URL
//                if let data = NSData(contentsOfURL: url!) {
//
//                    //make image from data, set to flickrPhoto.flickrImage
//                    let image = UIImage(data: data)
//                    flickrPhoto.flickrImage = image
//                    
//                    //set cellImage to data
//                    cellImage = image
//                } else {
//                    //failed to get data from url
//                    cellImage = UIImage(named: "no-image")
//                    flickrPhoto.flickrImage = cellImage
//                }
//                let request = NSURLRequest(URL: url!)
            } else {
                //failed to get flickrPhoto.urlString"
                cellImage = UIImage(named: "no-image")
            }
        }
        
        //set cell's image to cellImage
        dispatch_async(dispatch_get_main_queue(), {
            cell.cellImageView!.image = cellImage!
        })
        
        //set flickrPhoto imageto cellImage
        flickrPhoto.flickrImage = cellImage

        //adjust alpha if cell is selected
        if let index = find(self.selectedIndices, indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }
    }

    //hide/show noPhotosLabel
    func hideNoPhotosLabel(bool: Bool) {

        //TODO: MAKE TEXT LOOK PRETTY
        if bool {
//            self.noPhotosLabel.text = "Has Photos"    //DEBUG ONLY, REMOVE AFTER PHOTOS DISPLAY
            //TODO:  ACTUALLY DISPLAY PHOTOS
        } else {
            //displaying no photos label
            self.noPhotosLabel.text = "No Photos"
        }
        
        //hide noPhotosLabel based on var bool, do opposite for photoCollectionView
        dispatch_async(dispatch_get_main_queue(), {
            self.noPhotosLabel.hidden = bool
            self.photoCollectionView.hidden = !bool
        })
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
//        var gettingPhotosAlert = self.makeGettingPhotosAlert()
        
        //remove all photos
        self.deleteAllFlickrPhotos(self.selectedPin)
        
        //get photos, overwrites existing collection
        
        //TODO: WHY DO PHOTOS SHOW UP OUT OF ORDER??????????????????????
        
        
        self.getPhotos({() -> Void in
            self.newCollectionButton.enabled = true
        })
        
        //end alertView,enable newCollectionButton upon completion
//        gettingPhotosAlert.dismissViewControllerAnimated(true, completion: {
//            self.newCollectionButton.enabled = true
//        })
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
        
        //clear selectedIndicies array
        self.selectedIndices = [NSIndexPath]()
        
    }
    
    //remove all flicrPhotos
    func deleteAllFlickrPhotos(pin: Pin) {
        for flickrPhoto in self.fetchedResultsController.fetchedObjects as! [FlickrPhoto] {
            self.sharedContext.deleteObject(flickrPhoto)
        }
    }
    
    //get photos using pin cooridinate
    func getPhotos(completion: () -> Void) {

        //pass pin into FlickrClient
        FlickrClient.sharedInstance().getPhotos(self.selectedPin, perPage: FlickrClient.sharedInstance().perPage) { success, result, error in
            //successfully retreived result
            if success {

                //check if there are photos
                var hasPhotos: Bool = ((result![FlickrClient.Response.TOTAL] as! String).toInt() != 0)
                if hasPhotos {
                    
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
                //show no photos label depending on whether photos are present or not
                self.hideNoPhotosLabel(hasPhotos)
            } else {
                //alert user to error
                self.makeAlert(self, title: "Error", error: error)
                
                //no photos
                self.hideNoPhotosLabel(false)
            }
            //execute completion
            completion()
        }
    }
    
    //all commands to configure viewController
    func configureViewController() {
        //show navBar, setup delete button
        self.navigationController?.navigationBar.hidden = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "trashSelectedPhotos")
        self.navigationItem.rightBarButtonItem?.enabled = false
        
        //setup collectionView
        self.photoCollectionView.backgroundColor = UIColor.whiteColor()
        self.photoCollectionView.hidden = true
        
        //setup noPhotosLabel
        self.noPhotosLabel.text = "No Photos"
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
