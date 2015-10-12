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
        self.mapView.addAnnotation(selectedPin)//.annotation)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
        let mapWindow = MKCoordinateRegionMakeWithDistance(self.selectedPin.coordinate, 50000, 50000)
        self.mapView.setRegion(mapWindow, animated: true)
        
        //perform fetch
        self.fetchedResultsController.delegate = self
        self.fetchedResultsController.performFetch(nil)
        
        println(selectedPin)
        
        //get photos if no photos persisted with Pin
        if self.selectedPin.flickrPhotos.isEmpty {
            println("no photos persisted, getting photos")
            self.getPhotos(selectedPin, page: selectedPin.page as? Int, perPage: FlickrClient.sharedInstance().perPage) { success, error in
                
                //create gettingPhotosAlert
                //TODO: NEED BETTER ACTIVITY INDICATOR
//                var gettingPhotosAlert = self.makeGettingPhotosAlert()
                //display alert
//                println("showing getPhotosAlert")
//                self.presentViewController(gettingPhotosAlert, animated: true, completion: nil)
                
                //perform segue if successful
                if success {
                    println("finished retrieving photos")
                    
                    //check if photos count is non zero
                    var hasPhotos: Bool = (self.selectedPin.flickrPhotos.count != 0)
//                        gettingPhotosAlert.dismissViewControllerAnimated(true, completion: {
                            //reload photos
                            println("selectedPin.flickrPhotos = \(self.selectedPin.flickrPhotos.count)")
                            //show no photos label depending on whether photos are present or not
                            self.hideNoPhotosLabel(hasPhotos)
//                        })
                } else {
                    //alert user to error
                    println("failed to get all photos")
//                        gettingPhotosAlert.dismissViewControllerAnimated(true, completion: {
                            self.makeAlert(self, title: "Error", error: error)
                    
                            //no photos
                            self.hideNoPhotosLabel(false)
//                        })
                }
            }
        } else {
            println("persisted photos present, count = \(self.fetchedResultsController.fetchedObjects!.count)")
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
        println("sectionInfo.numberOfObjects = \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    //when cell is selected, change alpha, add index to selectedIndices
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        println("selecting cell at indexPath = \(indexPath.row)")
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

    }
    
    //cell to be populated
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //get cell and flickrPhoto
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let flickrPhoto = self.fetchedResultsController.objectAtIndexPath(indexPath) as! FlickrPhoto
        self.configureCell(cell, withFlickrPhoto: flickrPhoto, atIndexPath: indexPath)
        
        return cell
    }
    
    //create three fresh arrays when controller is about to make changes
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        println("willChangeContent")
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
            println("didChangeObject")
            
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
        println("didChangeContent")
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
        
        //check if flickrPhoto .urlString is "", set to no-image
        if flickrPhoto.urlString == "" {
            cellImage = UIImage(named: "no-image")
        } else {
            //check if image is downloaded and cached (flickrPhoto optional image param is set)
            if let flickrImage = flickrPhoto.flickrImage {
                //is downloaded and cached, set
                cellImage = flickrImage
            } else {
                //image needs to be downloaded, attempt to download, if failure, set to no-image
                if let flickrImage = FlickrClient.sharedInstance().imageFromURLstring(flickrPhoto.urlString!) {
                    cellImage = flickrImage
                } else {
                    cellImage = UIImage(named: "no-image")
                }
            }
            
            //set image of cell
            cell.cellImageView!.image = cellImage
            
            //adjust alpha if cell is selected
            if let index = find(self.selectedIndices, indexPath) {
                cell.alpha = 0.5
            } else {
                cell.alpha = 1.0
            }
        }
    }
    
//    func configureCell(cell: PhotoCollectionViewCell, withFlickrPhoto flickrPhoto: FlickrPhoto, atIndexPath indexPath: NSIndexPath) {
//
//        //get flickrPhoto object, set to cell's flickrPhoto param
//        if let flickrPhoto = self.fetchedResultsController.objectAtIndexPath(indexPath) as? FlickrPhoto {
//            println("flickrPhoto found at indexPath")
//            cell.flickrPhoto = flickrPhoto
//            
//            //get image for cell
//            if let cellImg = flickrPhoto.flickrImage {
//                println("made image, setting cell to new image")
//                cell.cellImageView.image = cellImg
//            } else {
//                println("setting cell to empty image")
//                cell.cellImageView.image = self.makeEmptyImage(cell)
//            }
//        } else {
//            //no flickrPhoto, make blank image
//            println("no flickrPhoto found at indexPath")
//            cell.cellImageView.image = self.makeEmptyImage(cell)
//        }
//        
//        //adjust alpha if cell is selected
//        if let index = find(self.selectedIndices, indexPath) {
//            cell.alpha = 0.5
//        } else {
//            cell.alpha = 1.0
//        }
//
//    }
    
    //hide/show noPhotosLabel
    func hideNoPhotosLabel(bool: Bool) {

        //TODO: MAKE TEXT LOOK PRETTY
        if bool {
            println("hiding no photos label")
//            self.noPhotosLabel.text = "Has Photos"    //DEBUG ONLY, REMOVE AFTER PHOTOS DISPLAY
            //TODO:  ACTUALLY DISPLAY PHOTOS
        } else {
            println("displaying no photos label")
            self.noPhotosLabel.text = "No Photos"
        }
        
        //hide noPhotosLabel based on var bool, do opposite for photoCollectionView
        dispatch_async(dispatch_get_main_queue(), {
            self.noPhotosLabel.hidden = /*false*/bool// - CHANGE BACK AFTER PHOTOS DISPLAY
            self.photoCollectionView.hidden = /*true*/ !bool
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
        var gettingPhotosAlert = self.makeGettingPhotosAlert()
        
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
    
    
//    func deleteSelectedColors() {
//        var colorsToDelete = [Color]()
//        
//        for indexPath in selectedIndexes {
//            colorsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Color)
//        }
//        
//        for color in colorsToDelete {
//            sharedContext.deleteObject(color)
//        }
//        
//        selectedIndexes = [NSIndexPath]()
//    }
    
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
