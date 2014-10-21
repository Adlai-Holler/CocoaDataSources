/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A subclass of AAPLDataSource with multiple child data sources, however, only one data source will be visible at a time. Load content messages will be sent only to the selected data source. When selected, if a data source is still in the initial state, it will receive a load content message.
  
 */

#import "AAPLDataSource.h"

/// A data source that switches among a number of child data sources.
@interface AAPLSegmentedDataSource : AAPLDataSource

/// Add a data source to the end of the collection. The title property of the data source will be used to populate a new segment in the UISegmentedControl associated with this data source.
- (void)addDataSource:(AAPLDataSource *)dataSource;

/// Remove the data source from the collection.
- (void)removeDataSource:(AAPLDataSource *)dataSource;

/// Clear the collection of data sources.
- (void)removeAllDataSources;

/// The collection of data sources contained within this segmented data source.
@property (nonatomic, readonly) NSArray *dataSources;

/// A reference to the selected data source.
@property (nonatomic, strong) AAPLDataSource *selectedDataSource;

/// The index of the selected data source in the collection.
@property (nonatomic) NSInteger selectedDataSourceIndex;

@end
