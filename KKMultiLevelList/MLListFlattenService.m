//
//  MLListFlattenService.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLListFlattenService.h"

@implementation MLListFlattenService

- (instancetype)init {
    if (self = [super init]) {
        _params = [[MLListFlattenParams alloc] init];
    }
    return self;
}

#pragma mark - Setter

- (void)setRootItems:(NSArray<id<MLListItemProtocol>> *)rootItems {
    _rootItems = rootItems;
    _visibleItems = [self visibleItemsForItems:self.rootItems level:0];
}

- (void)setStatusDidChangeHandler:(MLFlattenedItemStatusDidChangeHandler)statusDidChangeHandler {
    _statusDidChangeHandler = [statusDidChangeHandler copy];
    for (MLFlattenedItemModel *model in self.visibleItems) {
        model.statusDidChangeHandler = _statusDidChangeHandler;
    }
}

- (void)reloadVisibleItems {
    _visibleItems = [self visibleItemsForItems:self.rootItems level:0];
}

- (NSArray<MLFlattenedItemModel *> *)visibleItemsForItems:(NSArray<id<MLListItemProtocol>> *)items level:(NSInteger)level {
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [NSMutableArray array];
    for (id<MLListItemProtocol> item in items) {
        [self appendVisibleItemsForObject:item parent:nil level:level toArray:visibleItems];
    }
    return [visibleItems copy];
}

#pragma mark - Private

- (MLFlattenedItemModel *)flattenedItemModelWithObject:(id<MLListItemProtocol>)object
                                                parent:(MLFlattenedItemModel *)parent
                                                 level:(NSInteger)level
                                                  type:(MLFlattenedItemType)type {
    MLFlattenedItemModel *model = [[MLFlattenedItemModel alloc] initWithDifferableObject:object
                                                                                  parent:parent
                                                                                   level:level
                                                                                    type:type];
    model.statusDidChangeHandler = self.statusDidChangeHandler;
    return model;
}

- (void)appendVisibleItemsForObject:(id<MLListItemProtocol>)object
                             parent:(MLFlattenedItemModel *)parent
                              level:(NSInteger)level
                            toArray:(NSMutableArray<MLFlattenedItemModel *> *)visibleItems {
    MLFlattenedItemModel *cellItem = [self flattenedItemModelWithObject:object
                                                                  parent:parent
                                                                   level:level
                                                                    type:MLFlattenedItemTypeNormal];
    [visibleItems addObject:cellItem];
    
    NSInteger visibleChildrenCount = MIN(object.children.count, object.visibleChildrenCount);
    NSArray<id<MLListItemProtocol>> *visibleChildren = [object.children subarrayWithRange:NSMakeRange(0, visibleChildrenCount)];
    for (id<MLListItemProtocol> child in visibleChildren) {
        [self appendVisibleItemsForObject:child parent:cellItem level:level + 1 toArray:visibleItems];
    }
    
    if (self.params.usesFooter && object.totalChildrenCount > 0) {
        MLFlattenedItemModel *footerItem = [self flattenedItemModelWithObject:object
                                                                        parent:cellItem
                                                                         level:level
                                                                          type:MLFlattenedItemTypeFooter];
        [visibleItems addObject:footerItem];
    }
}

- (NSRange)visibleRangeForObject:(id<MLListItemProtocol>)object
                  inVisibleItems:(NSArray<MLFlattenedItemModel *> *)visibleItems {
    NSInteger startIndex = [self visibleIndexForObject:object type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
    if (startIndex == NSNotFound) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    MLFlattenedItemModel *startModel = visibleItems[startIndex];
    NSInteger endIndex = startIndex + 1;
    while (endIndex < visibleItems.count) {
        MLFlattenedItemModel *currentModel = visibleItems[endIndex];
        if (currentModel.differableObject != object && currentModel.level <= startModel.level) {
            break;
        }
        endIndex++;
    }
    
    return NSMakeRange(startIndex, endIndex - startIndex);
}

- (NSInteger)visibleIndexForObject:(id<MLListItemProtocol>)object
                              type:(MLFlattenedItemType)type
                    inVisibleItems:(NSArray<MLFlattenedItemModel *> *)visibleItems {
    for (NSInteger index = 0; index < visibleItems.count; index++) {
        MLFlattenedItemModel *visibleItem = visibleItems[index];
        if (visibleItem.differableObject == object && visibleItem.type == type) {
            return index;
        }
    }
    return NSNotFound;
}

- (void)replaceVisibleModelForObject:(id<MLListItemProtocol>)object
                                type:(MLFlattenedItemType)type
                      inVisibleItems:(NSMutableArray<MLFlattenedItemModel *> *)visibleItems {
    NSInteger index = [self visibleIndexForObject:object type:type inVisibleItems:visibleItems];
    if (index == NSNotFound) {
        return;
    }
    
    MLFlattenedItemModel *oldModel = visibleItems[index];
    MLFlattenedItemModel *newModel = [self flattenedItemModelWithObject:object
                                                                  parent:oldModel.parent
                                                                   level:oldModel.level
                                                                    type:type];
    [visibleItems replaceObjectAtIndex:index withObject:newModel];
}

- (void)removeVisibleModelForObject:(id<MLListItemProtocol>)object
                                type:(MLFlattenedItemType)type
                      inVisibleItems:(NSMutableArray<MLFlattenedItemModel *> *)visibleItems {
    NSInteger index = [self visibleIndexForObject:object type:type inVisibleItems:visibleItems];
    if (index == NSNotFound) {
        return;
    }
    
    [visibleItems removeObjectAtIndex:index];
}

#pragma mark - Action

- (void)appendVisibleChildenItemsForRootModel:(MLFlattenedItemModel *)model {
    if (model == nil) {
        return;
    }
    
    id<MLListItemProtocol> rootItem = model.differableObject;
    NSInteger oldVisibleChildrenCount = MIN(MAX(model.visibleChildrenCount, 0), rootItem.children.count);
    NSInteger expandBatchCount = MAX(self.params.expandBatchCount, 1);
    NSInteger newVisibleChildrenCount = self.params.usesFooter ? MIN(oldVisibleChildrenCount + expandBatchCount, rootItem.children.count) : rootItem.children.count;
    if (newVisibleChildrenCount <= oldVisibleChildrenCount) {
        return;
    }

    NSRange newChildrenRange = NSMakeRange(oldVisibleChildrenCount, newVisibleChildrenCount - oldVisibleChildrenCount);
    NSArray<id<MLListItemProtocol>> *newVisibleChildren = [rootItem.children subarrayWithRange:newChildrenRange];
    NSMutableArray<MLFlattenedItemModel *> *newFlattenedItems = [NSMutableArray array];
    MLFlattenedItemModel *parentModel = model.type == MLFlattenedItemTypeNormal ? model : model.parent;
    for (id<MLListItemProtocol> child in newVisibleChildren) {
        [self appendVisibleItemsForObject:child parent:parentModel level:model.level + 1 toArray:newFlattenedItems];
    }
    
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSInteger footerIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    NSInteger insertIndex = footerIndex;
    if (insertIndex == NSNotFound) {
        NSRange visibleRange = [self visibleRangeForObject:rootItem inVisibleItems:visibleItems];
        if (visibleRange.location == NSNotFound) {
            return;
        }
        insertIndex = visibleRange.location + visibleRange.length;
    }
    if (insertIndex > visibleItems.count) {
        return;
    }
    
    rootItem.visibleChildrenCount = newVisibleChildrenCount;
    
    NSIndexSet *insertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertIndex, newFlattenedItems.count)];
    [visibleItems insertObjects:newFlattenedItems atIndexes:insertIndexes];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    
    _visibleItems = [visibleItems copy];
}

- (void)deleteVisibleChildenItemsForRootModel:(MLFlattenedItemModel *)model {
    if (model == nil) {
        return;
    }
    
    id<MLListItemProtocol> deletedItem = model.differableObject;
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSRange deleteRange = [self visibleRangeForObject:deletedItem inVisibleItems:visibleItems];
    if (deleteRange.location == NSNotFound || deleteRange.length == 0) {
        return;
    }
    
    MLFlattenedItemModel *parentModel = model.parent;
    id<MLListItemProtocol> parentItem = parentModel.differableObject;
    NSMutableArray<id<MLListItemProtocol>> *rootItems = [self.rootItems mutableCopy];
    
    [visibleItems removeObjectsInRange:deleteRange];
    
    if (parentItem != nil) {
        NSUInteger childIndex = [parentItem.children indexOfObjectIdenticalTo:deletedItem];
        if (childIndex != NSNotFound) {
            NSInteger oldVisibleChildrenCount = parentItem.visibleChildrenCount;
            [parentItem.children removeObjectAtIndex:childIndex];
            parentItem.totalChildrenCount = MAX(parentItem.totalChildrenCount - 1, 0);
            if (childIndex < oldVisibleChildrenCount) {
                parentItem.visibleChildrenCount = MAX(oldVisibleChildrenCount - 1, 0);
            }
            parentItem.visibleChildrenCount = MIN(parentItem.visibleChildrenCount, parentItem.children.count);
            [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
            if (parentItem.children.count == 0 || parentItem.totalChildrenCount <= 0) {
                [self removeVisibleModelForObject:parentItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
            } else {
                [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
            }
        }
    } else {
        NSUInteger rootIndex = rootItems == nil ? NSNotFound : [rootItems indexOfObjectIdenticalTo:deletedItem];
        if (rootIndex != NSNotFound) {
            [rootItems removeObjectAtIndex:rootIndex];
            _rootItems = [rootItems copy];
        }
    }
    
    _visibleItems = [visibleItems copy];
}

- (void)collapseVisibleChildenItemsForRootModel:(MLFlattenedItemModel *)model {
    if (model == nil) {
        return;
    }
    
    id<MLListItemProtocol> rootItem = model.differableObject;
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSInteger rootIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
    if (rootIndex == NSNotFound) {
        return;
    }
    
    NSInteger footerIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    NSRange deleteRange = NSMakeRange(NSNotFound, 0);
    if (footerIndex != NSNotFound) {
        if (footerIndex > rootIndex + 1) {
            deleteRange = NSMakeRange(rootIndex + 1, footerIndex - rootIndex - 1);
        }
    } else {
        NSRange visibleRange = [self visibleRangeForObject:rootItem inVisibleItems:visibleItems];
        if (visibleRange.location != NSNotFound && visibleRange.length > 1) {
            deleteRange = NSMakeRange(visibleRange.location + 1, visibleRange.length - 1);
        }
    }
    
    if (deleteRange.location != NSNotFound && deleteRange.length > 0) {
        [visibleItems removeObjectsInRange:deleteRange];
    }
    
    rootItem.visibleChildrenCount = 0;
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    
    _visibleItems = [visibleItems copy];
}

@end
