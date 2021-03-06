//
//  FlickrREST.swift
//  VirtualTourist
//
//  Created by Brian Josel on 8/26/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import Foundation

//REST methods for FlickrClient
extension FlickrClient {
    
    //GET task
    func taskForGETRequest(urlString: String, requestType: String, completionHandler: (sucess: Bool, result: AnyObject?, error: NSError?) -> Void) -> NSURLSessionTask {
        
        //construct URL
        let url = NSURL(string: urlString)
        
        //create session
        let session = NSURLSession.sharedSession()
        
        //create request
        let request = NSURLRequest(URL: url!)
        
        //start request
        let task = session.dataTaskWithRequest(request) { data, response, error in
            //complete with error if request fails
            if let error = error {
                completionHandler(sucess: false, result: nil, error: error)
            } else {
                //successful request, check for type of request to understand how to handle result
                switch requestType {
                case FlickrClient.Request.JSON:
                    self.parseJSON(data!, completionHandler: completionHandler)
                case FlickrClient.Request.IMAGE:
                    completionHandler(sucess: true, result: data, error: nil)
                default:
                    print("invalid selection, aborting")
                    abort() //TODO: REMOVE PRIOR TO SUBMISSION
                }
            }
        }
        task.resume()
        return task
    }
    
    //JSON parser
    func parseJSON(data: NSData, completionHandler: (success: Bool, result: AnyObject?, error: NSError?) -> Void) {
        
        //error for pointer
        var error: NSError?
        
        //parse data into JSON object
        var parsedJSON : AnyObject!
        do {
            parsedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error1 as NSError {
            error = error1
            parsedJSON = nil
        }
        
        //check for error
        if let error = error {
            //complete with error
            completionHandler(success: false, result: nil, error: error)
        } else {
            //complete with parsed JSON
            completionHandler(success: true, result: parsedJSON, error: nil)
        }
    }
}