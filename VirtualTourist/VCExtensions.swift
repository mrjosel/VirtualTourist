//
//  VCExtensions.swift
//  VirtualTourist
//
//  Created by Brian Josel on 9/3/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import Foundation
import UIKit
import MapKit

//methods shared by VCs
extension UIViewController {

    //get photos using pin cooridinate
    func getPhotos(pin: MKAnnotationView, page: Int, perPage: Int, completionHandler: (success: Bool) -> Void) {
        println("GETTING PHOTOS")
        //pass pin into FlickrClient
        var gettingPhotosAlert = self.showGettingPhotosAlert()
        FlickrClient.sharedInstance().getPhotoURLs(pin, page: page, perPage: perPage) { success, result, error in
            if !success {
                //TODO: Make Alert function
                println("couldn't get photo urls")
                completionHandler(success: false)
            } else {
                //retrieved photoURLs
                println("got all the photos")
                FlickrClient.sharedInstance().maxPages = result![FlickrClient.OutputData.PAGES] as? Int
                FlickrClient.sharedInstance().photoURLs = FlickrClient.sharedInstance().maxPages == 0 ? [] : result![FlickrClient.OutputData.URLS] as! [String] //REPLACE WITH CORE DATA
                completionHandler(success: true)
            }
            println("dismissing getPhotosAlert")
            gettingPhotosAlert.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    //TODO: MAKE ALERT VIEW
    
    
    //indicator to show user that the app is retrieving photos
    //MAYBE REMOVE IN ORDER TO IMPLEMENT COREDATA
    
//    dismiss2015-09-10 08:57:26.176 VirtualTourist[36990:2614621] pushViewController:animated: called on <UINavigationController 0x7f9598e1f4f0> while an existing transition or presentation is occurring; the navigation stack will not be updated.
//    ing getPhotosAlert
    
    func showGettingPhotosAlert() -> UIAlertController {
        //make alertView
        var alertView = UIAlertController(title: "Getting photos...", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        //create activity indicator
        var indicator = UIActivityIndicatorView(frame: alertView.view.bounds)
        indicator.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        
        //add indicator to alertView as a subview
        alertView.view.addSubview(indicator)
        indicator.userInteractionEnabled = false
        indicator.startAnimating()
        
        
        //TODO: FIX APPEARANCE
        //set constraints
//        let views = ["pending" : alertView.view, "indicator" : indicator]
//        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[indicator]-(-50)-|", options: nil, metrics: nil, views: views)
//        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[indicator]|", options: nil, metrics: nil, views: views)
//        alertView.view.addConstraints(constraints)
        
        //display alert
        println("showing getPhotosAlert")
        self.presentViewController(alertView, animated: true, completion: nil)
        
        //return alertView to allow for dismissal upon completion of activity
        return alertView
    }
}