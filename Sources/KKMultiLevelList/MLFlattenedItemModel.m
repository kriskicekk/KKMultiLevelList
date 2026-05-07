//
//  MLFlattenedItemModel.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLFlattenedItemModel.h"
#import "MLListItemProtocol.h"

@implementation MLFlattenedItemModel

- (instancetype)initWithDifferableObject:(id<MLListItemProtocol>)object
                                  parent:(MLFlattenedItemModel *)parent
                                   level:(NSInteger)level
                                    type:(MLFlattenedItemType)type {
    NSParameterAssert(object);
    NSAssert(level >= 0, @"Flattened item level must be non-negative.");
    NSAssert(type == MLFlattenedItemTypeNormal || type == MLFlattenedItemTypeFooter, @"Flattened item type is invalid.");
    NSAssert(object.visibleChildrenCount >= 0, @"visibleChildrenCount must be non-negative.");
    NSAssert(object.totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");
    if (self = [super init]) {
        _differableObject = object;
        _parent = parent;
        _level = level;
        _type = type;
        
        _visibleChildrenCount = object.visibleChildrenCount;
        _totalChildrenCount = object.totalChildrenCount;
        
        // The initial status is derived from count snapshots. Transient UI
        // states such as loading are set later by the business interaction.
        if (_visibleChildrenCount == 0) {
            _status = MLFlattenedItemStatusCollapsed;
        } else if (_visibleChildrenCount > 0 && _visibleChildrenCount < _totalChildrenCount) {
            _status = MLFlattenedItemStatusPartiallyExpanded;
        } else if (_visibleChildrenCount >= _totalChildrenCount) {
            _status = MLFlattenedItemStatusFullyExpanded;
        }
    }
    return self;
}

#pragma mark - Setter

- (void)setVisibleChildrenCount:(NSInteger)visibleChildrenCount {
    NSAssert(visibleChildrenCount >= 0, @"visibleChildrenCount must be non-negative.");
    _visibleChildrenCount = visibleChildrenCount;
    self.differableObject.visibleChildrenCount = visibleChildrenCount;
}

- (void)setTotalChildrenCount:(NSInteger)totalChildrenCount {
    NSAssert(totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");
    _totalChildrenCount = totalChildrenCount;
    self.differableObject.totalChildrenCount = totalChildrenCount;
}

- (void)setStatus:(MLFlattenedItemStatus)status {
    if (_status == status) {
        return;
    }
    
    _status = status;
    // Status changes are UI-only changes. Notify the manager so it can reload
    // the current visible model without rebuilding the whole flattened list.
    if (self.statusDidChangeHandler) {
        self.statusDidChangeHandler(self);
    }
}

#pragma mark - Getter

- (NSInteger)remainingChildrenCount {
    return MAX(self.differableObject.totalChildrenCount - self.differableObject.visibleChildrenCount, 0);
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
        && model.status == self.status
        && model.visibleChildrenCount == self.visibleChildrenCount
        && model.totalChildrenCount == self.totalChildrenCount;
}

@end
