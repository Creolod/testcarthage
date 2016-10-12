//
//  NSTableView+AMInfiniteScroiling.h
//  AMInfiniteScrolling
//
//  Created by user on 10/10/16.
//  Copyright © 2016 Academ Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AMInfiniteScrollingView;

@interface NSTableView (AMInfiniteScroilling)

- (void)addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler;
- (void)triggerInfiniteScrolling;

@property (nonatomic, strong, readonly) NSClipView *clipView;
@property (nonatomic, strong, readonly) AMInfiniteScrollingView *infiniteScrollingView;
@property (nonatomic, assign) BOOL showsInfiniteScrolling;

@end

enum {
    AMInfiniteScrollingStateStopped = 0,
    AMInfiniteScrollingStateTriggered,
    AMInfiniteScrollingStateLoading,
    AMInfiniteScrollingStateAll = 10
};


typedef NSUInteger AMInfiniteScrollingState;

@interface AMInfiniteScrollingView : NSView

@property (nonatomic, readonly) AMInfiniteScrollingState state;
@property (nonatomic, readwrite) BOOL enabled;

- (void)startAnimating;
- (void)stopAnimating;

@end