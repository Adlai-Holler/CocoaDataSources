//
//  PhotoAlbumDataSource.swift
//  SmartMail
//
//  Created by Adlai Holler on 9/29/14.
//  Copyright (c) 2014 Bitlogica Inc. All rights reserved.
//

import UIKit
import Photos

class PhotoFetchResultDataSource: AAPLDataSource, PHPhotoLibraryChangeObserver {
    
    let fetchResult: PHFetchResult
    init(fetchResult: PHFetchResult) {
        self.fetchResult = fetchResult
        super.init()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    func photoLibraryDidChange(changeInstance: PHChange!) {
        let details = changeInstance.changeDetailsForFetchResult(fetchResult)
        notifyBatchUpdate {
            self.notifyItemsRemovedAtIndexPaths(self.indexPathsForIndices(details.removedIndexes))
            self.notifyItemsInsertedAtIndexPaths(self.indexPathsForIndices(details.insertedIndexes))
            self.notifyItemsRefreshedAtIndexPaths(self.indexPathsForIndices(details.changedIndexes))
            details.enumerateMovesWithBlock {from, to in
                self.notifyItemMovedFromIndexPath(NSIndexPath(forItem: from, inSection: 0), toIndexPaths: NSIndexPath(forItem: to, inSection: 0))
            }
        }
    }
    
    override func itemAtIndexPath(indexPath: NSIndexPath!) -> AnyObject! {
        assert(indexPath.section == 0)
        return fetchResult.objectAtIndex(indexPath.item)
    }
    
    override func indexPathsForItem(item: AnyObject!) -> [AnyObject]! {
        let idx = fetchResult.indexOfObject(item)
        if idx != Int(Foundation.NSNotFound) {
            return [NSIndexPath(forItem: idx, inSection: 0)]
        } else {
            return []
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    private func indexPathsForIndices(indexSet: NSIndexSet) -> [NSIndexPath] {
        var result = [NSIndexPath]()
        indexSet.enumerateIndexesUsingBlock {idx, stop in
            result.append(NSIndexPath(forItem: idx, inSection: 0))
        }
        return result
    }
}
