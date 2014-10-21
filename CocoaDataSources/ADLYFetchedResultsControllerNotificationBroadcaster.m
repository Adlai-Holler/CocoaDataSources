//
//  ADLYFetchedResultsControllerNotificationBroadcaster.m
//  SmartMail
//
//  Created by Adlai Holler on 7/2/14.
//  Copyright (c) 2014 Bitlogica Inc. All rights reserved.
//

#import "ADLYFetchedResultsControllerNotificationBroadcaster.h"
#import <objc/runtime.h>

NSString *const ADLYFetchedResultsControllerWillChangeContentNotification = @"ADLYFetchedResultsControllerWillChangeContentNotification";
NSString *const ADLYFetchedResultsControllerDidChangeContentNotification = @"ADLYFetchedResultsControllerDidChangeContentNotification";
NSString *const ADLYFetchedResultsControllerDidChangeObjectNotification = @"ADLYFetchedResultsControllerDidChangeObjectNotification";
NSString *const ADLYFetchedResultsControllerDidChangeSectionNotification = @"ADLYFetchedResultsControllerDidChangeSectionNotification";

NSString *const ADLYFetchedResultsControllerChangeTypeKey = @"ADLYFetchedResultsControllerChangeTypeKey";
NSString *const ADLYFetchedResultsControllerChangeIndexPathKey = @"ADLYFetchedResultsControllerChangeIndexPathKey";
NSString *const ADLYFetchedResultsControllerChangeNewIndexPathKey = @"ADLYFetchedResultsControllerChangeNewIndexPathKey";
NSString *const ADLYFetchedResultsControllerChangeObjectKey = @"ADLYFetchedResultsControllerChangeObjectKey";
NSString *const ADLYFetchedResultsControllerChangeSectionInfoKey = @"ADLYFetchedResultsControllerChangeSectionInfoKey";
NSString *const ADLYFetchedResultsControllerChangeSectionIndexKey = @"ADLYFetchedResultsControllerChangeSectionIndexKey";
static char const ADLYFetchedResultsControllerBroadcasterKey;
@implementation ADLYFetchedResultsControllerNotificationBroadcaster
- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    self = [super init];
    if (!self) { return nil; }
    _fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.delegate = self;
    return self;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if ([_forwardingDelegate respondsToSelector:_cmd]) {
        [_forwardingDelegate controllerDidChangeContent:controller];
    }
    [NSNotificationCenter.defaultCenter postNotificationName:ADLYFetchedResultsControllerDidChangeContentNotification object:_fetchedResultsController];
}

- (void)setForwardingDelegate:(id<NSFetchedResultsControllerDelegate,NSObject>)forwardingDelegate {
    if (forwardingDelegate == self) { return; }
    _forwardingDelegate = forwardingDelegate;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if ([_forwardingDelegate respondsToSelector:_cmd]) {
        [_forwardingDelegate controllerWillChangeContent:controller];
    }
    [NSNotificationCenter.defaultCenter postNotificationName:ADLYFetchedResultsControllerWillChangeContentNotification object:_fetchedResultsController];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    if ([_forwardingDelegate respondsToSelector:_cmd]) {
        [_forwardingDelegate controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:anObject, ADLYFetchedResultsControllerChangeObjectKey, @(type), ADLYFetchedResultsControllerChangeTypeKey, nil];
    if (indexPath) {
        userInfo[ADLYFetchedResultsControllerChangeIndexPathKey] = indexPath;
    }
    if (newIndexPath) {
        userInfo[ADLYFetchedResultsControllerChangeNewIndexPathKey] = newIndexPath;
    }
    [NSNotificationCenter.defaultCenter postNotificationName:ADLYFetchedResultsControllerDidChangeObjectNotification object:_fetchedResultsController userInfo:userInfo];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    if ([_forwardingDelegate respondsToSelector:_cmd]) {
        [_forwardingDelegate controller:controller didChangeSection:sectionInfo atIndex:sectionIndex forChangeType:type];
    }
    NSDictionary *userInfo = @{ ADLYFetchedResultsControllerChangeTypeKey: @(type), ADLYFetchedResultsControllerChangeSectionInfoKey: sectionInfo, ADLYFetchedResultsControllerChangeSectionIndexKey: @(sectionIndex) };
    [NSNotificationCenter.defaultCenter postNotificationName:ADLYFetchedResultsControllerDidChangeSectionNotification object:_fetchedResultsController userInfo:userInfo];
}

- (void)dealloc {
    if (_fetchedResultsController.delegate == self) {
        _fetchedResultsController.delegate = nil;
    }
}

@end

@implementation NSFetchedResultsController (SMBroadcasting)

+ (void)load {
    Method origSetDelegate = class_getInstanceMethod(self, @selector(setDelegate:));
    Method swizSetDelegate = class_getInstanceMethod(self, @selector(adly_setDelegate:));
    method_exchangeImplementations(origSetDelegate, swizSetDelegate);
}

- (void)adly_setDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    ADLYFetchedResultsControllerNotificationBroadcaster *bc = [self adly_notificationBroadcaster];
    if (bc && bc.forwardingDelegate != delegate && delegate != bc) {
        bc.forwardingDelegate = (id)delegate;
    }
    [self adly_setDelegate:delegate];
}

- (ADLYFetchedResultsControllerNotificationBroadcaster *)adly_notificationBroadcaster {
    return objc_getAssociatedObject(self, &ADLYFetchedResultsControllerBroadcasterKey);
}

- (void)adly_setNotificationBroadcaster:(ADLYFetchedResultsControllerNotificationBroadcaster *)newBroadcaster {
    newBroadcaster.forwardingDelegate = (id)self.delegate;
    objc_setAssociatedObject(self, &ADLYFetchedResultsControllerBroadcasterKey, newBroadcaster, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)adly_generatesNotifications {
    return [self adly_notificationBroadcaster] != nil;
}

- (void)adly_setGeneratesNotifications:(BOOL)adly_generatesNotifications {
    if (adly_generatesNotifications == [self adly_generatesNotifications]) { return; }
    if (adly_generatesNotifications) {
        ADLYFetchedResultsControllerNotificationBroadcaster *broadcaster = [[ADLYFetchedResultsControllerNotificationBroadcaster alloc] initWithFetchedResultsController:self];
        [self adly_setNotificationBroadcaster:broadcaster];
    } else {
        [self adly_setNotificationBroadcaster:nil];
    }
}

@end