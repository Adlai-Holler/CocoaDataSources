CocoaDataSources
================

A cluster of data source classes for building Cocoa apps. This library includes modified versions of classes from Apple's 2014 WWDC code sample "Advanced User Interfaces Using Collection View".

## Using CocoaDataSources

Add the repository as a submodule of your application. Open your application project in Xcode, and drag `CocoaDataSources.xcodeproj` into the file tree of your application project. Go to your application project, General tab, scroll to the bottom, and add `CocoaDataSources.framework` under `Embedded Binaries`. Use `@import CocoaDataSources` to import the framework at the top of a source file in your project (say, the precompiled header).

## AAPLDataSource

An abstract class that vends an ordered collection (a two-level index path structure) of items, and notifies a delegate of changes in the data. Data sources conform to both `UITableViewDataSource` and `UICollectionViewDataSource`.

## AAPLBasicDataSource

A data source that vends a mutable array. You can either set the `items` property all at once or call `mutableArrayValueForKey("items")` to retrieve an array that will act as a proxy to the vended collection. Changes made to this array are tracked and reported normally.

## AAPLComposedDataSource

A data source the acts as a proxy for an array of child data sources. Each child data source may vend 0 or more contiguous sections. Note the `dataSourceForSection:` method.

## PhotoFetchResultDataSource

A data source that vends the objects and changes from a `PHFetchResult`.

## FetchedResultsDataSource

A data source that vends the objects and changes from an `NSFetchedResultsController`.

## AAPLStateMachine 

A delightful state machine where each state is an `NSString` and it dynamically calls delegate methods based on state names. `didEnterLoading:`, `didExitBourgeoisie:`, etc

## AAPLContentLoading

A state machine subclass for managing content loading. Haven't touched this one yet but it seems nice.
