//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Brian Josel on 9/2/15.
//  Copyright (c) 2015 Brian Josel. All rights reserved.
//

import UIKit

//class for cell in collectionView
class PhotoCollectionViewCell: UICollectionViewCell {
    
    //image to be populated in cells
    @IBOutlet weak var cellImageView: UIImageView!
    
    //flickrPhoto, may not be required
    var flickrPhoto: FlickrPhoto?
    
    //how to cancel session task
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
