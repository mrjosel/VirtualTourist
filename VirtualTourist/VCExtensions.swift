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
        FlickrClient.sharedInstance().getPhotoURLs(pin, page: page, perPage: perPage) { success, result, error in
            if !success {
                //TODO: Make Alert function
                println("couldn't get photo urls")
                completionHandler(success: false)
            } else {
                //retrieved photoURLs
                println("got all the photos")
                println(result)
                FlickrClient.sharedInstance().maxPages = result![FlickrClient.OutputData.PAGES] as? Int
                FlickrClient.sharedInstance().photoURLs = FlickrClient.sharedInstance().maxPages == 0 ? [] : result![FlickrClient.OutputData.URLS] as! [String] //REPLACE WITH CORE DATA
                completionHandler(success: true)
            }
        }
    }
}