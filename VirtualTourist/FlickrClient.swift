//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/25/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//
//  Image caching method copied from FavoriteActors project
//  Copyright (c) 2015 Jason Schatz.

import Foundation

//class for managing all Flickr activity
class FlickrClient: NSObject {
    
    //perPage variable
    var perPage: Int
    
    //photoURLs TO BE REMOVED AFTER CORE DATA IMPLEMENTATION
//    var photoURLs = [String]()
    
    //initialize vars
    override init() {
        self.perPage = 20
        super.init()
    }
    
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
        static let BASE_PHOTO_URL = ""
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
        static let JSON = "json"
        static let IMAGE = "image"
    }
    
    //response
    struct Response {
        static let JSON = "json"
        static let NO_JSON_CALL_BACK = "1"
        
        //keys in response
        static let PHOTOS = "photos"
        static let PHOTO = "photo"
        static let ID = "id"
        static let FARM = "farm"
        static let SERVER = "server"
        static let SECRET = "secret"
        static let PAGES = "pages"
        static let TOTAL = "total"
        static let TITLE = "title"

    }
    
    //retreived data key
    struct OutputData {
        static let URLS = "urls"
        static let PAGES = "pages"
    }
    
    //Singleton
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static let sharedInstace = FlickrClient()
        }
        return Singleton.sharedInstace
    }
    
    //Caches for caching flickrPhoto images
    struct Caches {
        static let imageCache = ImageCache()
    }
}