/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A general purpose state machine implementation. The state machine will call methods on the delegate based on the name of the state. For example, when transitioning from StateA to StateB, the state machine will first call -shouldEnterStateA. If that method isn't implemented or returns YES, the state machine updates the current state. It then calls -didExitStateA followed by -didEnterStateB. Finally, if implemented, it will call -stateDidChange.
  Assumptions:
     • The number of states and transitions are relatively few
     • State transitions are relatively infrequent
     • Multithreadsafety/atomicity is handled at a higher level
  
 */

#import "AAPLStateMachine.h"

#import <objc/message.h>
#import <libkern/OSAtomic.h>

static NSString * const AAPLStateNil = @"Nil";

@implementation AAPLStateMachine {
    OSSpinLock _lock;
}

@synthesize currentState = _currentState;

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    _lock = OS_SPINLOCK_INIT;

    return self;
}

- (NSArray *)targets {
    id<AAPLStateMachineDelegate> delegate = self.delegate;
    return delegate ? @[ self, delegate ] : @[ self ];
}

- (NSString *)currentState
{
    __block NSString *currentState;
    
    // for atomic-safety, _currentState must not be released between the load of _currentState and the retain invocation
    OSSpinLockLock(&_lock);
    currentState = _currentState;
    OSSpinLockUnlock(&_lock);
    
    return currentState;
}

- (BOOL)applyState:(NSString *)toState
{
    return [self _setCurrentState:toState];
}

- (void)setCurrentState:(NSString *)toState
{
    [self _setCurrentState:toState];
}

- (BOOL)_setCurrentState:(NSString *)toState
{
    NSString *fromState = self.currentState;
       
    if (self.shouldLogStateTransitions)
        NSLog(@" ••• request state change from %@ to %@", fromState, toState);

    NSString *appliedToState = [self _validateTransitionFromState:fromState toState:toState];
    if (!appliedToState)
        return NO;

    // ...send will-change message for downstream KVO support...
    SEL genericWillChangeAction = @selector(stateWillChange);
    SEL genericWillChangeActionWSender = @selector(stateWillChange:);
    typedef void (*ObjCMsgSendReturnVoidWSender)(id, SEL, id);
    ObjCMsgSendReturnVoidWSender sendMsgReturnVoidWSender = (ObjCMsgSendReturnVoidWSender)objc_msgSend;
    typedef void (*ObjCMsgSendReturnVoid)(id, SEL);
    ObjCMsgSendReturnVoid sendMsgReturnVoid = (ObjCMsgSendReturnVoid)objc_msgSend;
    for (id target in [self targets]) {
        if ([target respondsToSelector:genericWillChangeActionWSender]) {
            sendMsgReturnVoidWSender(target, genericWillChangeActionWSender, self);
        } else if ([target respondsToSelector:genericWillChangeAction]) {
            sendMsgReturnVoid(target, genericWillChangeAction);
        }
    }
    [self willChangeValueForKey:@"currentState"];
    OSSpinLockLock(&_lock);
    _currentState = [appliedToState copy];
    OSSpinLockUnlock(&_lock);
    [self didChangeValueForKey:@"currentState"];
    
    // ... send messages
    [self _performTransitionFromState:fromState toState:appliedToState];

    return [toState isEqual:appliedToState];
}

- (NSString *)_missingTransitionFromState:(NSString *)fromState toState:(NSString *)toState
{
    if ([_delegate respondsToSelector:@selector(missingTransitionFromState:toState:)])
        return [_delegate missingTransitionFromState:fromState toState:toState];
    return [self missingTransitionFromState:fromState toState:toState];
}

- (NSString *)missingTransitionFromState:(NSString *)fromState toState:(NSString *)toState
{
    [NSException raise:@"IllegalStateTransition" format:@"cannot transition from %@ to %@", fromState, toState];
    return nil;
}

- (NSString *)_validateTransitionFromState:(NSString *)fromState toState:(NSString *)toState
{
    // Transitioning to the same state (fromState == toState) is always allowed. If it's explicitly included in its own validTransitions, the standard method calls below will be invoked. This allows us to avoid creating states that exist only to reexecute transition code for the current state.

    // Raise exception if attempting to transition to nil -- you can only transition *from* nil
    if (!toState) {
        NSLog(@"  ••• %@ cannot transition to <nil> state", self);
        toState = [self _missingTransitionFromState:fromState toState:toState];
        if (!toState) {
            return nil;
        }
    }

    // Raise exception if this is an illegal transition (toState must be a validTransition on fromState)
    if (fromState) {
        id validTransitions = self.validTransitions[fromState];
        BOOL transitionSpecified = YES;
        
        // Multiple valid transitions
        if ([validTransitions isKindOfClass:[NSArray class]]) {
            if (![validTransitions containsObject:toState]) {
                transitionSpecified = NO;
            }
        }
        // Otherwise, single valid transition object
        else if (![validTransitions isEqual:toState]) {
            transitionSpecified = NO;
        }
        
        if (!transitionSpecified) {
            // Silently fail if implict transition to the same state
            if ([fromState isEqualToString:toState]) {
                if (self.shouldLogStateTransitions)
                    NSLog(@"  ••• %@ ignoring reentry to %@", self, toState);
                return nil;
            }
            
            if (self.shouldLogStateTransitions)
                NSLog(@"  ••• %@ cannot transition to %@ from %@", self, toState, fromState);
            toState = [self _missingTransitionFromState:fromState toState:toState];
            if (!toState)
                return nil;
        }
    }
    
    // Allow target to opt out of this transition (preconditions)
    typedef BOOL (*ObjCMsgSendReturnBool)(id, SEL);
    ObjCMsgSendReturnBool sendMsgReturnBool = (ObjCMsgSendReturnBool)objc_msgSend;
    typedef BOOL (*ObjCMsgSendReturnBoolWSender)(id, SEL, id);
    ObjCMsgSendReturnBoolWSender sendMsgReturnBoolWSender = (ObjCMsgSendReturnBoolWSender)objc_msgSend;
    NSString *baseSelString = [@"shouldEnter" stringByAppendingString:toState];
    SEL enterStateActionWSender = NSSelectorFromString([baseSelString stringByAppendingString:@":"]);
    SEL enterStateAction = NSSelectorFromString(baseSelString);
    for (id target in [self targets]) {
        SEL usedAction = nil;
        BOOL disallowed = NO;
        if ([target respondsToSelector:enterStateActionWSender]) {
            if (!sendMsgReturnBoolWSender(target, enterStateActionWSender, self)) {
                usedAction = enterStateActionWSender;
                disallowed = YES;
            }
        } else if ([target respondsToSelector:enterStateAction] && !sendMsgReturnBool(target, enterStateAction)) {
            usedAction = enterStateAction;
            disallowed = YES;
        }
        if (disallowed) {
            NSLog(@"  ••• %@ transition disallowed to %@ from %@ (via %@)", self, toState, fromState, NSStringFromSelector(usedAction));
            toState = [self _missingTransitionFromState:fromState toState:toState];
        }
    }

    return toState;
}

- (void)_performTransitionFromState:(NSString *)fromState toState:(NSString *)toState
{
    // Subclasses may implement several different selectors to handle state transitions:
    //
    //  did enter state (didEnterPaused)
    //  did exit state (didExitPaused)
    //  transition between states (stateDidChangeFromPausedToPlaying)
    //  generic transition handler (stateDidChange), for common tasks
    //
    // Any and all of these that are implemented will be invoked.

    if (self.shouldLogStateTransitions)
        NSLog(@"  ••• %@ state change from %@ to %@", self, fromState, toState);
    typedef void (*ObjCMsgSendReturnVoidWSender)(id, SEL, id);
    typedef void (*ObjCMsgSendReturnVoid)(id, SEL);
    ObjCMsgSendReturnVoidWSender sendMsgReturnVoidWSender = (ObjCMsgSendReturnVoidWSender)objc_msgSend;
    ObjCMsgSendReturnVoid sendMsgReturnVoid = (ObjCMsgSendReturnVoid)objc_msgSend;
    for (id target in [self targets]) {
        if (fromState) {
            NSString *baseSelString = [@"didExit" stringByAppendingString:fromState];
            SEL exitStateActionWSender = NSSelectorFromString([baseSelString stringByAppendingString:@":"]);
            if ([target respondsToSelector:exitStateActionWSender]) {
                sendMsgReturnVoidWSender(target, exitStateActionWSender, self);
            } else {
                SEL exitStateAction = NSSelectorFromString(baseSelString);
                if ([target respondsToSelector:exitStateAction]) {
                    sendMsgReturnVoid(target, exitStateAction);
                }
            }
        }
        
        NSString *baseSelString_Enter = [@"didEnter" stringByAppendingString:toState];
        SEL enterStateActionWSender = NSSelectorFromString([baseSelString_Enter stringByAppendingString:@":"]);
        if ([target respondsToSelector:enterStateActionWSender]) {
            sendMsgReturnVoidWSender(target, enterStateActionWSender, self);
        } else {
            SEL enterStateAction = NSSelectorFromString(baseSelString_Enter);
            if ([target respondsToSelector:enterStateAction]) {
                sendMsgReturnVoid(target, enterStateAction);
            }
        }
        
        NSString *fromStateNotNil = fromState ? fromState : AAPLStateNil;
        NSString *baseSelString_transition = [NSString stringWithFormat:@"stateDidChangeFrom%@To%@", fromStateNotNil, toState];
        SEL transitionActionWSender = NSSelectorFromString([baseSelString_transition stringByAppendingString:@":"]);
        if ([target respondsToSelector:transitionActionWSender]) {
            sendMsgReturnVoidWSender(target, transitionActionWSender, self);
        } else {
            SEL transitionAction = NSSelectorFromString(baseSelString_transition);
            if ([target respondsToSelector:transitionAction]) {
                sendMsgReturnVoid(target, transitionAction);
            }
        }
        

        SEL genericDidChangeActionWSender = NSSelectorFromString(@"stateDidChange:");
        if ([target respondsToSelector:genericDidChangeActionWSender]) {
            sendMsgReturnVoidWSender(target, genericDidChangeActionWSender, self);
        } else {
            SEL genericDidChangeAction = @selector(stateDidChange);
            if ([target respondsToSelector:genericDidChangeAction]) {
                sendMsgReturnVoid(target, genericDidChangeAction);
            }
            
        }
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; currentState = %@>", self.class, self, self.currentState];
}
@end
