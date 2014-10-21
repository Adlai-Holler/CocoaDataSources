@import CoreData;

extern NSString *const ADLYFetchedResultsControllerWillChangeContentNotification;
extern NSString *const ADLYFetchedResultsControllerDidChangeContentNotification;
extern NSString *const ADLYFetchedResultsControllerDidChangeObjectNotification;
extern NSString *const ADLYFetchedResultsControllerDidChangeSectionNotification;

extern NSString *const ADLYFetchedResultsControllerChangeTypeKey;
extern NSString *const ADLYFetchedResultsControllerChangeIndexPathKey;
extern NSString *const ADLYFetchedResultsControllerChangeNewIndexPathKey;
extern NSString *const ADLYFetchedResultsControllerChangeObjectKey;
extern NSString *const ADLYFetchedResultsControllerChangeSectionInfoKey;
extern NSString *const ADLYFetchedResultsControllerChangeSectionIndexKey;

#define SMFRCDidChangeObjectNoteUnpack(__userInfo) \
  NSFetchedResultsChangeType type = [__userInfo[ADLYFetchedResultsControllerChangeTypeKey] unsignedIntegerValue]; \
  NSIndexPath *indexPath = __userInfo[ADLYFetchedResultsControllerChangeIndexPathKey];\
  NSIndexPath *newIndexPath = __userInfo[ADLYFetchedResultsControllerChangeNewIndexPathKey];\
  id anObject = __userInfo[ADLYFetchedResultsControllerChangeObjectKey];

@interface ADLYFetchedResultsControllerNotificationBroadcaster : NSObject<NSFetchedResultsControllerDelegate>
-(instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) id<NSFetchedResultsControllerDelegate, NSObject> forwardingDelegate;
@end

@interface NSFetchedResultsController (ADLYBroadcasting)
/** NOTE: When this is set, the `delegate` is set to a notification broadcaster. The `forwardingDelegate` of this broadcaster is automatically updated to any new delegates set while this is YES. 
    Normal FRC delegate usage will be unaffected.
 */
@property (nonatomic, setter=adly_setGeneratesNotifications:) BOOL adly_generatesNotifications;
@end
