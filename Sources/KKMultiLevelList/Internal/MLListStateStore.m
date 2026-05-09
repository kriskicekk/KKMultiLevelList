//
//  MLListStateStore.m
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/5/8.
//

#import "MLListStateStore.h"

@interface MLListStateStore ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *visibleChildrenCounts;

@end

@implementation MLListStateStore

- (instancetype)init {
    if (self = [super init]) {
        _visibleChildrenCounts = [NSMutableDictionary dictionary];
    }
    return self;
}

- (nullable NSString *)keyForItem:(id<MLListItemProtocol>)item {
    NSParameterAssert(item);
    id<NSObject> diffIdentifier = [item diffIdentifier];
    NSAssert(diffIdentifier != nil, @"MLListItemProtocol diffIdentifier must not be nil.");
    if (diffIdentifier == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@", diffIdentifier];
}

- (NSInteger)visibleChildrenCountForItem:(id<MLListItemProtocol>)item
              initialVisibleChildrenCount:(NSInteger)initialVisibleChildrenCount {
    NSInteger clampedInitialVisibleChildrenCount = MAX(initialVisibleChildrenCount, 0);
    NSString *key = [self keyForItem:item];
    if (key == nil) {
        return clampedInitialVisibleChildrenCount;
    }

    NSNumber *visibleChildrenCount = self.visibleChildrenCounts[key];
    if (visibleChildrenCount == nil) {
        visibleChildrenCount = @(clampedInitialVisibleChildrenCount);
        self.visibleChildrenCounts[key] = visibleChildrenCount;
    }
    return visibleChildrenCount.integerValue;
}

- (void)setVisibleChildrenCount:(NSInteger)visibleChildrenCount
                        forItem:(id<MLListItemProtocol>)item {
    NSInteger clampedVisibleChildrenCount = MAX(visibleChildrenCount, 0);
    NSString *key = [self keyForItem:item];
    if (key == nil) {
        return;
    }
    self.visibleChildrenCounts[key] = @(clampedVisibleChildrenCount);
}

- (void)removeStateForItem:(id<MLListItemProtocol>)item {
    NSString *key = [self keyForItem:item];
    if (key == nil) {
        return;
    }
    [self.visibleChildrenCounts removeObjectForKey:key];
}

@end
