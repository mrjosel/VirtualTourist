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
    func getPhotoURLs(pin: Pin, page: Int?, perPage: Int, completionHandler: (success: Bool, result: [String: AnyObject]?, error: NSError?) -> Void) {
        
        //get lat and lon values
        let lat = pin.coordinate.latitude
        let lon = pin.coordinate.longitude
        
        //create params for Flickr GET method
        let params : [String: AnyObject] = [
            FlickrClient.Params.LAT : lat,
            FlickrClient.Params.LON : lon,
            FlickrClient.Params.PAGE : page != nil ? page! : 1,
            FlickrClient.Params.PER_PAGE : perPage
        ]
        
        //make urlString for request, attempt request
        let urlString = FlickrClient.sharedInstance().createURLString(params)
        
        println("beginning GET request")
        //invoke GET method
        let task = FlickrClient.sharedInstance().taskForGETRequest(urlString) {success, result, error in
            //if error, complete with error
            if let error = error {
                println("error in getPhotos GET request")
                completionHandler(success: false, result: nil, error: error)
            } else {
                println("successful GET request in getPhotos")
                //get array of urlStrings for photos in result
                if let parsedJSON = result as? [String: AnyObject] {
                    println("successfully casted JSON to [[String: AnyObject]]")
                    if let photosDict = parsedJSON[FlickrClient.Response.PHOTOS] as? [String: AnyObject] {
                        println("successfully retrieved photosDict as [String: AnyObject]")
                        println(photosDict)
                        if let photosArray = photosDict[FlickrClient.Response.PHOTO] as? [[String: AnyObject]] {
                            //add array of urlStrings to dict
                            var photoURLstrings = self.makePhotoURLs(photosArray)
                            
                            //add key/val pair for number of pages in result
                            photoURLstrings[FlickrClient.OutputData.PAGES] = photosDict[FlickrClient.Response.PAGES] as! Int
                            
                            //complete with handler
                            completionHandler(success: true, result: photoURLstrings, error: nil)
                        } else {
                            println("failed to retrieve photosArray")
                            completionHandler(success: false, result: nil, error: NSError(domain: "retrieving photosDict", code: 999, userInfo: nil))
                        }
                    } else {
                        //failed to cast photosDict
                        println("failed to cast photosDict")
                        completionHandler(success: false, result: nil, error: NSError(domain: "casting photoDict", code: 999, userInfo: nil))
                    }
                } else {
                    //casting of result to [[String: AnyObject]] failed
                    println("casting of result to [[String: AnyObject]] failed")
                    completionHandler(success: false, result: nil, error: NSError(domain: "Casting result to parsedJSON", code: 999, userInfo: nil))
                }
            }
        }
    }
    
    //makes photo URLs from dictionary of photo data from JSON
    //resut is a dict so that getPhotoURLs can also add key/val pair for number of pages
    func makePhotoURLs(photoArray: [[String: AnyObject]]) -> [String: AnyObject] {
        /*******FORMAT OF URL BASED ON DICT KEY/VALS
        
        https://farm1.staticflickr.com/2/1418878_1e92283336_m.jpg
        
        farm-id: 1
        server-id: 2
        photo-id: 1418878
        secret: 1e92283336
        size: m - THIS IS OPTIONAL, WILL USE m IN ALL PHOTOS
        */
        
        //output array of photoURLstrings
        var outputDict = [String: AnyObject]()
        var urlArray = [String]()
        if photoArray.count > 0 {
            for photo in photoArray {
                //get params for URL
                let farmID = photo[FlickrClient.Response.FARM] as! Int
                let serverID = photo[FlickrClient.Response.SERVER] as! String
                let photoID = photo[FlickrClient.Response.ID] as! String
                let secret = photo[FlickrClient.Response.SECRET] as! String
                //TODO: WHY DOES CASTING TO INT ON FARMID WORK BUT NOT ON SERVERID????
                
                //construct URLstring
                let urlString = "https://farm\(farmID).staticflickr.com/\(serverID)/\(photoID)_\(secret)_m.jpg"

                //append to outputArray
                urlArray.append(urlString)
                
                outputDict[FlickrClient.OutputData.URLS] = urlArray
            }
        }
        
        return outputDict
    }
    
    //getting image using urlString
    func imageFromURLstring(urlString: String) -> UIImage? {
        println("getting flickrImage fromURLString")
        //make url from urlString
        var url = NSURL(string: urlString)
        
        //get data at url
        if let imgData = NSData(contentsOfURL: url!) {
            //return image from data
            println("return flickrImage from data")
            return UIImage(data: imgData)!
        } else {
            //no data at URL, return nil
            println("no image from data, returning empty image pic")
            return nil
        }
    }
}