//
//  MLListFlattenService.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLListFlattenService.h"

@implementation MLListFlattenService

- (NSArray<MLFlattenedItemModel *> *)getVisibleItems {
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [NSMutableArray array];
    for (id<MLListItemProtocol> item in self.rootItems) {
        [self appendVisibleItemsForObject:item level:0 toArray:visibleItems];
    }
    return [visibleItems copy];
}

#pragma mark - Private

- (void)appendVisibleItemsForObject:(id<MLListItemProtocol>)object
                              level:(NSInteger)level
                            toArray:(NSMutableArray<MLFlattenedItemModel *> *)visibleItems {
    MLFlattenedItemModel *normalItem = [[MLFlattenedItemModel alloc] initWithDifferableObject:object level:level type:MLFlattenedItemTypeNormal];
    [visibleItems addObject:normalItem];
    
    NSInteger visibleChildrenCount = MAX(object.children.count, object.visibleChildrenCount);
    NSArray<id<MLListItemProtocol>> *visibleChildren = [object.children subarrayWithRange:NSMakeRange(0, visibleChildrenCount)];
    for (id<MLListItemProtocol> child in visibleChildren) {
        [self appendVisibleItemsForObject:child level:level + 1 toArray:visibleItems];
    }
    
    if (object.totalChildrenCount > 0) {
        MLFlattenedItemModel *footerItem = [[MLFlattenedItemModel alloc] initWithDifferableObject:object level:level type: MLFlattenedItemTypeFooter];
        [visibleItems addObject:footerItem];
    }
}

@end
