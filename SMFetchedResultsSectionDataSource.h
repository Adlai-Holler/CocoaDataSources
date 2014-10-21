//
//  SMFetchedResultsSectionDataSource.h
//  SmartMail
//
//  Created by Adlai Holler on 7/2/14.
//  Copyright (c) 2014 Bitlogica Inc. All rights reserved.
//

#import "AAPLBasicDataSource.h"

/** NOTE: The associated fetchedResultsController will have sm_generatesNotifications set as part of initialization. If that property is set to NO, associated instances of this class will stop working.
 */
@interface SMFetchedResultsSectionDataSource : AAPLDataSource
- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;
- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController section:(NSInteger)section;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

