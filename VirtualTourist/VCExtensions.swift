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
    
    //create flickrPhoto objects from urlStrings
    func makeFlickrPhotos(urlStrings: [String]) -> [FlickrPhoto] {
        //return value
        var flickrPhotos : [FlickrPhoto]
        
        for urlString in urlStrings {
            var flickrPhoto = FlickrPhoto(urlString: urlString, context: self.sharedContext)
        }
    }

    //get photos using pin cooridinate
    func getPhotos(pin: /*MKAnnotationView*/Pin, page: Int, perPage: Int, completionHandler: (success: Bool, error: NSError?) -> Void) {
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
//                FlickrClient.sharedInstance().maxPages = result![FlickrClient.OutputData.PAGES] as? Int
                pin.pages = result![FlickrClient.OutputData.PAGES] as? Int
//                FlickrClient.sharedInstance().photoURLs = FlickrClient.sharedInstance().maxPages == 0 ? [] : result![FlickrClient.OutputData.URLS] as! [String] //REPLACE WITH CORE DATA
                pin.flickrPhotos = pin.pages == 0 ? [] : result![FlickrClient.OutputData.URLS] as! [String]
            }
            //complete with handler
            completionHandler(success: success, error: error)
        }
    }
    
    //alert function
    func makeAlert(hostVC: UIViewController, title: String, error: NSError?) -> Void {
        //handler for OK button depending on VC
        var handler: ((alert: UIAlertAction!) -> (Void))?
        var messageText: String!
        
        if let error = error {
            messageText = error.localizedDescription
        } else {
            messageText = "Press OK to Continue"
        }
        
        //create UIAlertVC
        var alertVC = UIAlertController(title: title, message: messageText, preferredStyle: UIAlertControllerStyle.Alert)
        
        //create action
        let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: handler)
        
        //add actions to alertVC
        alertVC.addAction(ok)
        dispatch_async(dispatch_get_main_queue(), {
            //present alertVC
            hostVC.presentViewController(alertVC, animated: true, completion: nil)
        })
    }
    
    //shorthand function to create custom error
    func errorHandle(domain: String, errorString: String) -> NSError {
        return NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "\(errorString)"])
    }
    
    
    //indicator to show user that the app is retrieving photos
    func showGettingPhotosAlert() -> UIAlertController {
        println("creating getting photos alertView")
        
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