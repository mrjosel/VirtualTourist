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
            allParams[key] = (val as! String)
        }
        
        
        //output url, starting with BASE_URL
        var urlString: String = FlickrClient.URLs.BASE_URL
        
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
    func getPhotoURLs(pin: MKAnnotationView, page: Int, per_page: Int, completionHandler: (success: Bool, result: [String]?, error: NSError?) -> Void) {
        
        //get lat and lon values
        let lat = pin.annotation.coordinate.latitude
        let lon = pin.annotation.coordinate.longitude
        
        //create params for Flickr GET method
        let params : [String: AnyObject] = [
            FlickrClient.Params.LAT : lat,
            FlickrClient.Params.LON : lon,
            FlickrClient.Params.PAGE : page,
            FlickrClient.Params.PER_PAGE : per_page
        ]
        
        //make urlString for request, attempt request
        let urlString = FlickrClient.sharedInstance().createURLString(params)
        
        //invoke GET method
        let task = FlickrClient.sharedInstance().taskForGETRequest(urlString) {success, result, error in
            //if error, complete with error
            if let error = error {
                completionHandler(success: false, result: nil, error: error)
            } else {
                //get array of urlStrings for photos in result
                if let parsedJSON = result as? [[String: AnyObject]] {
                    let photoURLstrings = self.makePhotoURLs(parsedJSON)
                    completionHandler(success: true, result: photoURLstrings, error: nil)
                } else {
                    //casting of result to [[String: AnyObject]] failed
                    println("casting of result to [[String: AnyObject]] failed")
                    completionHandler(success: false, result: nil, error: NSError(domain: "Casting result to parsedJSON", code: 999, userInfo: nil))
                }
            }
        }
    }
    
    //makes photo URLs from dictionary of photo data from JSON
    func makePhotoURLs(photoDict: [[String: AnyObject]]) -> [String] {
        /*******FORMAT OF URL BASED ON DICT KEY/VALS
        
        https://farm1.staticflickr.com/2/1418878_1e92283336_m.jpg
        
        farm-id: 1
        server-id: 2
        photo-id: 1418878
        secret: 1e92283336
        size: m - THIS IS OPTIONAL, WILL USE m IN ALL PHOTOS
        */
        
        //output array of photoURLstrings
        var outputArray = [String]()
        if photoDict.count > 0 {
            for photo in photoDict {
                //get params for URL
                let farm_id = photo[FlickrClient.Response.FARM] as! Int
                let server_id = photo[FlickrClient.Response.SERVER] as! Int
                let photo_id = photo[FlickrClient.Response.PHOTO] as! Int
                let secret = photo[FlickrClient.Response.SECRET] as! String
                
                //construct URLstring
                let urlString = "https://farm\(farm_id).staticflickr.com/\(server_id)/\(photo_id)_\(secret)_m.jpg"

                //append to outputArray
                outputArray.append(urlString)
            }
        }
        
        return outputArray
    }
}