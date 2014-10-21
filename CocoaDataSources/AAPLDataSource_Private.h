/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The base data source class.
  
  This file contains methods used internally by subclasses. These methods are not considered part of the public API of AAPLDataSource. It is possible to implement fully functional data sources without using these methods.
  
 */

#import "AAPLDataSource.h"

@protocol AAPLDataSourceDelegate;


@interface AAPLDataSource ()

- (void)stateWillChange;
- (void)stateDidChange;

- (void)enqueuePendingUpdateBlock:(dispatch_block_t)block;
- (void)executePendingUpdates;

- (NSIndexPath *)localIndexPathForGlobalIndexPath:(NSIndexPath *)globalIndexPath;

/// Is this data source the root data source? This depends on proper set up of the delegate property. Container data sources ALWAYS act as the delegate for their contained data sources.
@property (nonatomic, readonly, getter = isRootDataSource) BOOL rootDataSource;

/// Whether this data source should display the placeholder.
@property (nonatomic, readonly) BOOL shouldDisplayPlaceholder;

- (void)notifySectionsInserted:(NSIndexSet *)sections;
- (void)notifySectionsRemoved:(NSIndexSet *)sections;
- (void)notifySectionMovedFrom:(NSInteger)section to:(NSInteger)newSection;

@end
