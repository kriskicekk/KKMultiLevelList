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
    if (self = [super init]) {
        _differableObject = object;
        _parent = parent;
        _level = level;
        _type = type;
        
        _visibleChildrenCount = object.visibleChildrenCount;
        _totalChildrenCount = object.totalChildrenCount;
        
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
    _visibleChildrenCount = visibleChildrenCount;
    self.differableObject.visibleChildrenCount = visibleChildrenCount;
}

- (void)setTotalChildrenCount:(NSInteger)totalChildrenCount {
    _totalChildrenCount = totalChildrenCount;
    self.differableObject.totalChildrenCount = totalChildrenCount;
}

- (void)setStatus:(MLFlattenedItemStatus)status {
    if (_status == status) {
        return;
    }
    
    _status = status;
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
    return [NSString stringWithFormat:@"%@-%ld", [self.differableObject diffIdentifier], (long)self.type];
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object {
    if (self == object) {
        return YES;
    }
    
    if (![(id)object isKindOfClass:[MLFlattenedItemModel class]]) {
        return NO;
    }
    
    MLFlattenedItemModel *model = (MLFlattenedItemModel *)object;
    
    return [self.differableObject isEqualToDiffableObject:model.differableObject]
        && model.type == self.type
        && model.level == self.level
        && model.status == self.status;
}

@end
