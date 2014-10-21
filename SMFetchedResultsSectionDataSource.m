
//
//  SMFetchedResultsSectionDataSource.m
//  SmartMail
//
//  Created by Adlai Holler on 7/2/14.
//  Copyright (c) 2014 Bitlogica Inc. All rights reserved.
//

#import "SMFetchedResultsSectionDataSource.h"
#import "SMFetchedResultsControllerNotificationBroadcaster.h"
@interface SMFetchedResultsSectionDataSource() <NSFetchedResultsControllerDelegate>

@property (nonatomic) NSInteger section;
@property (nonatomic) BOOL isFRCChanging;
@property (nonatomic, strong) NSMutableArray *bufferedChanges;
@property (nonatomic, strong, readonly) id<NSFetchedResultsSectionInfo> sectionInfo;
@end

@implementation SMFetchedResultsSectionDataSource
@synthesize numberOfSections = _numberOfSections;

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    return [self initWithFetchedResultsController:fetchedResultsController section:0];
}

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController section:(NSInteger)section {
    self = [super init];
    if (!self) { return nil; }

    _section = section;
    _fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.sm_generatesNotifications = YES;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(controllerWillChangeContentNote:) name:SMFetchedResultsControllerWillChangeContentNotification object:_fetchedResultsController];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(controllerDidChangeContentNote:) name:SMFetchedResultsControllerDidChangeContentNotification object:_fetchedResultsController];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(controllerDidChangeSectionNote:) name:SMFetchedResultsControllerDidChangeSectionNotification object:_fetchedResultsController];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(controllerDidChangeObjectNote:) name:SMFetchedResultsControllerDidChangeObjectNotification object:_fetchedResultsController];
    _bufferedChanges = [[NSMutableArray alloc] init];
    [_fetchedResultsController performFetch:NULL];
    _numberOfSections = [self.sectionInfo numberOfObjects] > 0 ? 1 : 0;
    return self;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        indexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:_section];
        return [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    return nil;
}

- (NSArray *)indexPathsForItem:(id)item {
    if ([item isKindOfClass:NSManagedObject.class]) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:item];
        return indexPath ? @[ indexPath ] : @[ ];
    } else {
        return @[ ];
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (id<NSFetchedResultsSectionInfo>)sectionInfo {
    if (_section >= _fetchedResultsController.sections.count) {
        return nil;
    }
    return _fetchedResultsController.sections[_section];
}

- (void)_processBufferedChanges {
    if (self.bufferedChanges.count < 1) { return; }
    //// reload data when creating/removing section – doing animations causes crashes in AAPLComposedDataSource
    if (self.numberOfSections == 0) {
        _numberOfSections = 1;
        [self notifyDidReloadData];
        [self.bufferedChanges removeAllObjects];
        return;
    }
    
    [self notifyBatchUpdate:^{

        for (NSDictionary *userInfo in self.bufferedChanges) {
            SMFRCDidChangeObjectNoteUnpack(userInfo)
            if (indexPath) {
                indexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:0];
            }
            if (newIndexPath) {
                newIndexPath = [NSIndexPath indexPathForItem:newIndexPath.item inSection:0];
            }
            switch (type) {
                case NSFetchedResultsChangeDelete:
                    [self notifyItemsRemovedAtIndexPaths:@[ indexPath ]];
                    break;
                case NSFetchedResultsChangeInsert:
                    [self notifyItemsInsertedAtIndexPaths:@[ newIndexPath ]];
                    break;
                case NSFetchedResultsChangeMove: {
                    BOOL fromSelf = indexPath.section == _section;
                    BOOL toSelf = newIndexPath.section == _section;
                    if (fromSelf) {
                        [self notifyItemsRemovedAtIndexPaths:@[ indexPath ]];
                    }
                    if (toSelf) {
                        [self notifyItemsInsertedAtIndexPaths:@[ newIndexPath ]];
                    }
                } break;
                case NSFetchedResultsChangeUpdate: {
                    [self notifyItemsRefreshedAtIndexPaths:@[ indexPath ]];
                } break;
                default:
                    break;
            }
        }
    }];
    if (self.numberOfSections == 1 && [self collectionView:nil numberOfItemsInSection:0] == 0) {
        _numberOfSections = 0;
        [self notifyDidReloadData];
    }
    [self.bufferedChanges removeAllObjects];
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(NO, @"cannot remove an item from a fetched results data source");
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContentNote:(NSNotification *)note {
    [self notifyWillBatchUpdate];
    _isFRCChanging = YES;
}

- (void)controllerDidChangeContentNote:(NSNotification *)note {
    _isFRCChanging = NO;
    [self _processBufferedChanges];
}

- (void)controllerDidChangeObjectNote:(NSNotification *)note {
    NSDictionary *info = note.userInfo;
    [self.bufferedChanges addObject:info];
}

- (void)controllerDidChangeSectionNote:(NSNotification *)note {
    // TODO: support section changes
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSAssert(_isFRCChanging == NO, @"queried for data while FRC is changing. Why?");
    if (section == 0) {
        return self.sectionInfo.numberOfObjects;
    }
    NSAssert(NO, @"Collection view is asking for a different section than expected.");
    return 0;
}
@end
