//
//  MLFlattenedItemModel.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "Internal/MLFlattenedItemModelInternal.h"
#import "MLListItemProtocol.h"

static MLListItemDisplayStatus MLFlattenedItemDisplayStatusForCounts(NSInteger visibleChildrenCount, NSInteger totalChildrenCount) {
    if (visibleChildrenCount <= 0) {
        return MLListItemDisplayStatusCollapsed;
    } else if (visibleChildrenCount < totalChildrenCount) {
        return MLListItemDisplayStatusPartiallyExpanded;
    } else {
        return MLListItemDisplayStatusFullyExpanded;
    }
}

@implementation MLFlattenedItemModel

- (instancetype)initWithDifferableObject:(id<MLListItemProtocol>)object
                                  parent:(MLFlattenedItemModel *)parent
                                   level:(NSInteger)level
                                    type:(MLFlattenedItemType)type {
    return [self initWithDifferableObject:object
                                   parent:parent
                                    level:level
                                     type:type
                     visibleChildrenCount:0];
}

- (instancetype)initWithDifferableObject:(id<MLListItemProtocol>)object
                                  parent:(MLFlattenedItemModel *)parent
                                   level:(NSInteger)level
                                    type:(MLFlattenedItemType)type
                    visibleChildrenCount:(NSInteger)visibleChildrenCount {
    NSParameterAssert(object);
    NSAssert(level >= 0, @"Flattened item level must be non-negative.");
    NSAssert(type == MLFlattenedItemTypeCell || type == MLFlattenedItemTypeFooter, @"Flattened item type is invalid.");
    NSAssert(visibleChildrenCount >= 0, @"visibleChildrenCount must be non-negative.");
    NSAssert(object.totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");
    MLListItemDisplayStatus displayStatus = MLFlattenedItemDisplayStatusForCounts(visibleChildrenCount, object.totalChildrenCount);
    if (self = [super init]) {
        _differableObject = object;
        _parent = parent;
        _level = level;
        _type = type;
        
        _itemState = [[MLListItemState alloc] initWithVisibleChildrenCount:visibleChildrenCount
                                                             displayStatus:displayStatus];
        [self installDisplayStatusDidChangeHandlerForItemState];
        _totalChildrenCount = object.totalChildrenCount;
    }
    return self;
}

#pragma mark - Setter

- (void)setItemState:(MLListItemState *)itemState {
    NSParameterAssert(itemState);
    _itemState.displayStatusDidChangeHandler = nil;
    _itemState = [itemState copy];
    [self installDisplayStatusDidChangeHandlerForItemState];
}

- (void)setTotalChildrenCount:(NSInteger)totalChildrenCount {
    NSAssert(totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");
    _totalChildrenCount = totalChildrenCount;
}

#pragma mark - Getter

- (NSInteger)remainingChildrenCount {
    return MAX(self.totalChildrenCount - self.itemState.visibleChildrenCount, 0);
}

#pragma mark - Private

- (void)installDisplayStatusDidChangeHandlerForItemState {
    __weak typeof(self) weakSelf = self;
    self.itemState.displayStatusDidChangeHandler = ^(__unused MLListItemState *state) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        // Display status changes are UI-only changes. Notify the manager so it
        // can reload the current visible model without rebuilding the whole
        // flattened list.
        if (strongSelf.displayStatusDidChangeHandler) {
            strongSelf.displayStatusDidChangeHandler(strongSelf);
        }
    };
}

#pragma mark - IGListDiffable

- (id<NSObject>)diffIdentifier {
    // A business object can appear twice in the flat list: one normal row and
    // one footer row. Include the type so IGListKit treats them as distinct.
    id<NSObject> diffIdentifier = [self.differableObject diffIdentifier];
    NSAssert(diffIdentifier != nil, @"MLListItemProtocol diffIdentifier must not be nil.");
    return [NSString stringWithFormat:@"%@-%ld", diffIdentifier, (long)self.type];
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object {
    if (self == object) {
        return YES;
    }
    
    if (![(id)object isKindOfClass:[MLFlattenedItemModel class]]) {
        return NO;
    }
    
    MLFlattenedItemModel *model = (MLFlattenedItemModel *)object;
    
    // Compare the UI-facing snapshots as well as the business object. Footer
    // text and loading state can change even when the underlying object identity
    // stays the same.
    return [self.differableObject isEqualToDiffableObject:model.differableObject]
        && model.type == self.type
        && model.level == self.level
        && model.itemState.displayStatus == self.itemState.displayStatus
        && model.itemState.visibleChildrenCount == self.itemState.visibleChildrenCount
        && model.totalChildrenCount == self.totalChildrenCount;
}

@end
