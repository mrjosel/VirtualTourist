//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/25/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import Foundation

//class for managing all Flickr activity
class FlickrClient {
    
    static let masterParams = [
        FlickrClient.Params.API : FlickrClient.Keys.API_KEY,
        FlickrClient.Params.METHOD : FlickrClient.Methods.SEARCH,
        FlickrClient.Params.JSON_CALLBACK : FlickrClient.Response.NO_JSON_CALL_BACK,
        FlickrClient.Params.RESPONSE_FORMAT : FlickrClient.Response.JSON
    ]
    
    //constant key variables
    struct Keys {
        static let API_KEY = "8f5b01973b15272e6298bd40e57efe56"
        static let SECRET = "d7313001977dafee"
    }
    
    //urls
    struct URLs {
        static let BASE_URL = "https://api.flickr.com/services"
    }
    
    //methods
    struct Methods {
        static let SEARCH = "flickr.photos.search"
    }
    
    struct Params {
        static let LAT = "lat"
        static let LON = "lon"
        static let PER_PAGE = "per_page"
        static let PAGE = "page"
        static let RESPONSE_FORMAT = "format"
        static let API = "api_key"
        static let SECRET = "secret"
        static let METHOD = "method"
        static let JSON_CALLBACK = "nojsoncallback"
    }
    
    //request
    struct Request {
        static let REST = "rest"
    }
    
    //response
    struct Response {
        static let JSON = "json"
        static let NO_JSON_CALL_BACK = "1"
    }
    
    //creates url for GET request
    class func createURLString(params: [String: AnyObject]) -> String {
        
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
    
    //Singleton
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static let sharedInstace = FlickrClient()
        }
        return Singleton.sharedInstace
    }
}