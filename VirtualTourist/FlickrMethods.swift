//
//  FlickrMethods.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/26/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import Foundation
import MapKit

//methods used by FLickr
extension FlickrClient {
    
    //creates url for GET request
    func createURLString(params: [String: AnyObject]) -> String {
        
        //add params to new array including defaultParams
        var allParams = [String : AnyObject]()
        for (key, val) in FlickrClient.masterParams {
            allParams[key] = val
        }
        
        
        for (key, val) in params {
            allParams[key] = val
        }
        
        
        //output url, starting with BASE_URL
        let urlString: String = FlickrClient.URLs.BASE_URL
        
        //join key/val pairs with "=", make new array
        var newArray = [String]()
        for (key, val) in allParams {
            newArray.append("\(key)=\(val)")
        }
        
        //make urlAppendix by joining newArray items with "&"
        let urlAppendix = "&".join(newArray)
        
        //add rest request and paramString to url and return
        return urlString + "/" + FlickrClient.Request.REST + "/?" + urlAppendix
    }
    
    //get all photos using MKAnnotationView
    func getPhotos(pin: Pin, perPage: Int, completionHandler: (success: Bool, result: [String: AnyObject]?, error: NSError?) -> Void) {
        
        //get lat and lon values
        let lat = pin.coordinate.latitude
        let lon = pin.coordinate.longitude
        
        //create params for Flickr GET method
        let params : [String: AnyObject] = [
            FlickrClient.Params.LAT : lat,
            FlickrClient.Params.LON : lon,
            FlickrClient.Params.PAGE : pin.page != nil ? pin.page! : 1,
            FlickrClient.Params.PER_PAGE : perPage
        ]
        
        //make urlString for request, attempt request
        let urlString = FlickrClient.sharedInstance().createURLString(params)
        
        //invoke GET method
        _ = FlickrClient.sharedInstance().taskForGETRequest(urlString, requestType: FlickrClient.Request.JSON){ success, result, error in
            
            //if error, complete with error
            if let error = error {
                completionHandler(success: false, result: nil, error: error)
            } else {
                //get array of urlStrings for photos in result
                if let parsedJSON = result as? [String: AnyObject] {
                    //get photos portion and complete with handler
                    let photosResult = parsedJSON[FlickrClient.Response.PHOTOS] as! [String: AnyObject]
                    completionHandler(success: true, result: photosResult, error: nil)
                } else {
                    //casting of result to [[String: AnyObject]] failed
                    completionHandler(success: false, result: nil, error: NSError(domain: "Casting result to parsedJSON", code: 999, userInfo: nil))
                }
            }
        }
    }
    
    //getting image using urlString- UNUSED
    func imageFromURLstring(urlString: String) -> UIImage? {
        //make url from urlString
        let url = NSURL(string: urlString)
        
        //get data at url
        if let imgData = NSData(contentsOfURL: url!) {
            //return image from data
            return UIImage(data: imgData)!
        } else {
            //no data at URL, return nil
            return nil
        }
    }
}