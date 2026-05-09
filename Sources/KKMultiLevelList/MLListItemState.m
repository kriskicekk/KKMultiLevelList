//
//  MLListItemState.m
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/5/8.
//

#import "MLListItemState.h"

@interface MLListItemState ()

@property (nonatomic, nullable, copy) void (^displayStatusDidChangeHandler)(MLListItemState *state);

@end

@implementation MLListItemState

- (instancetype)init {
    return [self initWithVisibleChildrenCount:0
                                displayStatus:MLListItemDisplayStatusDefault];
}

- (instancetype)initWithVisibleChildrenCount:(NSInteger)visibleChildrenCount
                               displayStatus:(MLListItemDisplayStatus)displayStatus {
    NSAssert(visibleChildrenCount >= 0, @"visibleChildrenCount must be non-negative.");
    if (self = [super init]) {
        _visibleChildrenCount = visibleChildrenCount;
        _displayStatus = displayStatus;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    MLListItemState *state = [[[self class] allocWithZone:zone] initWithVisibleChildrenCount:self.visibleChildrenCount
                                                                               displayStatus:self.displayStatus];
    return state;
}

- (void)setVisibleChildrenCount:(NSInteger)visibleChildrenCount {
    NSAssert(visibleChildrenCount >= 0, @"visibleChildrenCount must be non-negative.");
    _visibleChildrenCount = visibleChildrenCount;
}

- (void)setDisplayStatus:(MLListItemDisplayStatus)displayStatus {
    if (_displayStatus == displayStatus) {
        return;
    }

    _displayStatus = displayStatus;
    if (self.displayStatusDidChangeHandler) {
        self.displayStatusDidChangeHandler(self);
    }
}

@end
