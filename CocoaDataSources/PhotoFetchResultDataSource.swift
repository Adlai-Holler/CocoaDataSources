
import UIKit
import Photos

public class PhotoFetchResultDataSource: AAPLDataSource, PHPhotoLibraryChangeObserver {
    
    let fetchResult: PHFetchResult
    public init(fetchResult: PHFetchResult) {
        self.fetchResult = fetchResult
        super.init()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    public func photoLibraryDidChange(changeInstance: PHChange) {
		guard let details = changeInstance.changeDetailsForFetchResult(fetchResult) else {
			return
		}
		dispatch_async(dispatch_get_main_queue()) {
			self.notifyBatchUpdate {
				if let removed = details.removedIndexes {
					self.notifyItemsRemovedAtIndexPaths(self.indexPathsForIndices(removed))
				}
				if let inserted = details.insertedIndexes {
					self.notifyItemsInsertedAtIndexPaths(self.indexPathsForIndices(inserted))
				}
				if let changed = details.changedIndexes {
					self.notifyItemsRefreshedAtIndexPaths(self.indexPathsForIndices(changed))
				}
				details.enumerateMovesWithBlock {from, to in
					self.notifyItemMovedFromIndexPath(NSIndexPath(forItem: from, inSection: 0), toIndexPaths: NSIndexPath(forItem: to, inSection: 0))
				}
			}
		}
    }
    
    override public func itemAtIndexPath(indexPath: NSIndexPath!) -> AnyObject! {
        assert(indexPath.section == 0)
        return fetchResult.objectAtIndex(indexPath.item)
    }
    
    override public func indexPathsForItem(item: AnyObject!) -> [AnyObject]! {
        let idx = fetchResult.indexOfObject(item)
        if idx != Int(Foundation.NSNotFound) {
            return [NSIndexPath(forItem: idx, inSection: 0)]
        } else {
            return []
        }
    }
    
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
