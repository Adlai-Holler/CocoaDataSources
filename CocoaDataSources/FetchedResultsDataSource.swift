import CoreData

// TODO: use generics when Swift compiler stops crashing
public class FetchedResultsDataSource: AAPLDataSource {
    let fetchedResultsController: NSFetchedResultsController
    var bufferedChanges: [NSDictionary] = []
    var isFRCChanging = false
    init(fetchedResultsController: NSFetchedResultsController) {
        fetchedResultsController.adly_generatesNotifications = true
        self.fetchedResultsController = fetchedResultsController
        super.init()


        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "controllerWillChangeContentNote:", name: ADLYFetchedResultsControllerWillChangeContentNotification, object: fetchedResultsController)
        nc.addObserver(self, selector: "controllerDidChangeContentNote:", name: ADLYFetchedResultsControllerDidChangeContentNotification, object: fetchedResultsController)
        nc.addObserver(self, selector: "controllerDidChangeSectionNote:", name: ADLYFetchedResultsControllerDidChangeSectionNotification, object: fetchedResultsController)
        nc.addObserver(self, selector: "controllerDidChangeObjectNote:", name: ADLYFetchedResultsControllerDidChangeObjectNotification, object: fetchedResultsController)
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        if error != nil {
            println("Error setting up FetchedResultsDataSource: error running fetch: \(error)")
        }
    }
    
    override public func itemAtIndexPath(indexPath: NSIndexPath!) -> AnyObject! {
        return fetchedResultsController.objectAtIndexPath(indexPath)
    }
    
    override public func indexPathsForItem(item: AnyObject!) -> [AnyObject]!  {
        if let ip = fetchedResultsController.indexPathForObject(item) {
            return [ip]
        } else {
            return []
        }
    }

    override public func removeItemAtIndexPath(indexPath: NSIndexPath!) {
        fatalError("cannot remove item from fetched results data source")
    }
    
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
    }
    
    override public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func controllerWillChangeContentNote(note: NSNotification) {
        notifyWillBatchUpdate()
        isFRCChanging = true
    }
    
    func controllerDidChangeContentNote(note: NSNotification) {
        isFRCChanging = false
        processBufferedChanges()
    }
    
    func controllerDidChangeObjectNote(note: NSNotification) {
        bufferedChanges.append(note.userInfo!)
    }
    
    func controllerDidChangeSectionNote(note: NSNotification) {
        bufferedChanges.append(note.userInfo!)
    }
    
    var isCurrentChangeRefreshOnly: Bool?
    private func processBufferedChanges() {
        if bufferedChanges.count < 1 { return }
        
        isCurrentChangeRefreshOnly = true
        for userInfo in bufferedChanges {
            let type = NSFetchedResultsChangeType(rawValue: userInfo[ADLYFetchedResultsControllerChangeTypeKey]!.unsignedLongValue)!
            if type != .Update {
                isCurrentChangeRefreshOnly = false
                break
            }
        }
        notifyBatchUpdate { for userInfo in self.bufferedChanges {
            let type = NSFetchedResultsChangeType(rawValue: userInfo[ADLYFetchedResultsControllerChangeTypeKey]!.unsignedLongValue)!
            if let section = userInfo[ADLYFetchedResultsControllerChangeSectionIndexKey] as? Int {
                // section change
                switch type {
                case .Insert: self.notifySectionsInserted(NSIndexSet(index: section))
                case .Delete: self.notifySectionsRemoved(NSIndexSet(index: section))
                default: fatalError("Unexpected section change type")
                }
            } else {
                // object change
                let indexPath = userInfo[ADLYFetchedResultsControllerChangeIndexPathKey] as NSIndexPath!
                let newIndexPath = userInfo[ADLYFetchedResultsControllerChangeNewIndexPathKey] as NSIndexPath!
                switch type {
                case .Insert: self.notifyItemsInsertedAtIndexPaths([newIndexPath])
                case .Delete: self.notifyItemsRemovedAtIndexPaths([indexPath])
                case .Move: self.notifyItemMovedFromIndexPath(indexPath, toIndexPaths: newIndexPath)
                case .Update: self.notifyItemsRefreshedAtIndexPaths([indexPath])
            }
            }
        }}
        isCurrentChangeRefreshOnly = nil
        bufferedChanges.removeAll(keepCapacity: false)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
