//
//  NSTableView+AMInfiniteScroiling.m
//  AMInfiniteScrolling
//
//  Created by user on 10/10/16.
//  Copyright © 2016 Academ Media. All rights reserved.
//

#import "NSTableView+AMInfiniteScroilling.h"
#import <objc/runtime.h>

static CGFloat const AMInfiniteScrollingViewHeight = 60;

@interface AMInfiniteScrollingView ()

@property (nonatomic, copy) void (^infiniteScrollingHandler)(void);

@property (nonatomic, strong) NSProgressIndicator *progressIndicatorView;
@property (nonatomic, readwrite) AMInfiniteScrollingState state;

@property (nonatomic, weak) NSTableView *tableView;
@property (nonatomic, weak) NSClipView *clipView;
@property (nonatomic, weak) NSScrollView *scrollView;

@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;
- (void)setScrollViewContentInset:(NSEdgeInsets)insets;
- (void)addObservers;
- (void)removeObservers;

@end

static char NSScrollViewInfiniteScrollingView;
NSEdgeInsets scrollViewOriginalContentInsets;

@implementation NSTableView (AMInfiniteScroilling)

@dynamic clipView;

- (void)addInfiniteScrollingWithScrollView:(NSScrollView*)scrollView andActionHandler:(void (^)(void))actionHandler {
    if(!self.infiniteScrollingView) {
        AMInfiniteScrollingView* view = [[AMInfiniteScrollingView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, AMInfiniteScrollingViewHeight)];
        view.infiniteScrollingHandler = actionHandler;
        self.clipView.automaticallyAdjustsContentInsets = NO;
        view.tableView = self;
        view.clipView = self.clipView;
        view.scrollView = (NSScrollView*)self.clipView.superview;
        [self addSubview:view];
        self.infiniteScrollingView = view;
        self.showsInfiniteScrolling = YES;
    }
}

-(NSClipView*)clipView {
    if ([self.superview isKindOfClass:[NSClipView class]]) {
        return (NSClipView*)self.superview;
    }
    return nil;
}

- (void)triggerInfiniteScrolling {
    self.infiniteScrollingView.state = AMInfiniteScrollingStateTriggered;
    [self.infiniteScrollingView startAnimating];
}

- (void)setInfiniteScrollingView:(AMInfiniteScrollingView *)infiniteScrollingView {
    [self willChangeValueForKey:@"NSScrollViewInfiniteScrollingView"];
    objc_setAssociatedObject(self, &NSScrollViewInfiniteScrollingView,
                             infiniteScrollingView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"NSScrollViewInfiniteScrollingView"];
}

- (AMInfiniteScrollingView *)infiniteScrollingView {
    return objc_getAssociatedObject(self, &NSScrollViewInfiniteScrollingView);
}

- (void)setShowsInfiniteScrolling:(BOOL)showsInfiniteScrolling {
    self.infiniteScrollingView.hidden = !showsInfiniteScrolling;
    if(!showsInfiniteScrolling)
        [self.infiniteScrollingView removeObservers];
    else {
        [self.infiniteScrollingView addObservers];
        [self.infiniteScrollingView setNeedsLayout:YES];
        self.infiniteScrollingView.frame = CGRectMake(0, 0, self.infiniteScrollingView.bounds.size.width, AMInfiniteScrollingViewHeight);
    }
}

- (BOOL)showsInfiniteScrolling {
    return !self.infiniteScrollingView.hidden;
}
@end

#pragma mark - AMInfiniteScrollingView
@implementation AMInfiniteScrollingView

@synthesize infiniteScrollingHandler;

@synthesize state = _state;
@synthesize tableView = _tableView;
@synthesize progressIndicatorView = _progressIndicatorView;

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        self.state = AMInfiniteScrollingStateStopped;
        self.enabled = YES;
    }
    
    return self;
}

- (void)willMoveToSuperview:(NSView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        NSTableView *tableView = (NSTableView *)self.superview;
        if (tableView.showsInfiniteScrolling)
            [self removeObservers];
    }
}

-(void)removeObservers{
    if (self.isObserving) {
        [[NSNotificationCenter defaultCenter]removeObserver:NSViewBoundsDidChangeNotification];
        self.isObserving = NO;
    }
}

-(void)addObservers{
    if (!self.isObserving) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(scrollViewDidScroll)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:self.clipView];
        self.isObserving = YES;
    }
}

#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    NSEdgeInsets currentInsets = self.clipView.contentInsets;
    currentInsets.top = 0;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForInfiniteScrolling {
    NSEdgeInsets currentInsets = self.clipView.contentInsets;
    currentInsets.top = AMInfiniteScrollingViewHeight;
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(NSEdgeInsets)contentInset {
    self.clipView.contentInsets = contentInset;
}

#pragma mark - Observing

- (void)scrollViewDidScroll {
    if(self.state != AMInfiniteScrollingStateLoading && self.enabled) {
        if(self.state == AMInfiniteScrollingStateTriggered && self.clipView.bounds.origin.y == 0)
            self.state = AMInfiniteScrollingStateLoading;
        else if(self.scrollView.verticalScroller.floatValue < 0.2 && self.state == AMInfiniteScrollingStateStopped)
            self.state = AMInfiniteScrollingStateTriggered;
        else if(self.scrollView.verticalScroller.floatValue > 0.2  && self.state != AMInfiniteScrollingStateStopped)
            self.state = AMInfiniteScrollingStateStopped;
    }
}

#pragma mark - Getters

- (NSProgressIndicator *)progressIndicatorView {
    if(!_progressIndicatorView) {
        _progressIndicatorView = [[NSProgressIndicator alloc] init];
        [_progressIndicatorView setStyle:NSProgressIndicatorSpinningStyle];
        _progressIndicatorView.displayedWhenStopped = NO;
        
        [self.clipView addSubview:_progressIndicatorView];
    }
    return _progressIndicatorView;
}

#pragma mark - Setters

- (void)setState:(AMInfiniteScrollingState)newState {
    if(_state == newState)
        return;
    
    AMInfiniteScrollingState previousState = _state;
    _state = newState;
    [self.progressIndicatorView setFrame:CGRectMake(self.clipView.frame.size.width/2, -AMInfiniteScrollingViewHeight, AMInfiniteScrollingViewHeight, AMInfiniteScrollingViewHeight)];
    
    if (newState == AMInfiniteScrollingStateStopped) {
        [self resetScrollViewContentInset];
        [self.progressIndicatorView stopAnimation:self];
    }
    else if (newState == AMInfiniteScrollingStateTriggered) {
        [self.progressIndicatorView startAnimation:self];
    }
    else if (newState == AMInfiniteScrollingStateLoading) {
        [self setScrollViewContentInsetForInfiniteScrolling];
        [self.progressIndicatorView startAnimation:self];
    }
    
    if(previousState == AMInfiniteScrollingStateTriggered && newState == AMInfiniteScrollingStateLoading && self.infiniteScrollingHandler && self.enabled)
        self.infiniteScrollingHandler();
}

#pragma mark -

- (void)triggerRefresh {
    self.state = AMInfiniteScrollingStateTriggered;
    self.state = AMInfiniteScrollingStateLoading;
}

- (void)startAnimating{
    self.state = AMInfiniteScrollingStateLoading;
}

- (void)stopAnimating {
    self.state = AMInfiniteScrollingStateStopped;
}

@end
