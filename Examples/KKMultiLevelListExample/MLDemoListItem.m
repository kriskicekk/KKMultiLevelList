//
//  MLDemoListItem.m
//  KKMultiLevelList
//
//  Created by Codex on 2026/4/27.
//

#import "MLDemoListItem.h"

@implementation MLDemoListItem

- (instancetype)initWithItemId:(NSString *)itemId
                         title:(NSString *)title
            totalChildrenCount:(NSInteger)totalChildrenCount {
    if (self = [super init]) {
        _itemId = [itemId copy];
        _title = [title copy];
        _children = [NSMutableArray array];
        _totalChildrenCount = totalChildrenCount;
        _visibleChildrenCount = 0;
    }
    return self;
}

- (id<NSObject>)diffIdentifier {
    return self.itemId;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object {
    if (self == object) {
        return YES;
    }
    if (![(id)object isKindOfClass:MLDemoListItem.class]) {
        return NO;
    }
    MLDemoListItem *item = (MLDemoListItem *)object;
    return [self.itemId isEqualToString:item.itemId]
        && self.children.count == item.children.count
        && self.visibleChildrenCount == item.visibleChildrenCount
        && self.totalChildrenCount == item.totalChildrenCount;
}

@end
