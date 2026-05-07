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
    oldModel.statusDidChangeHandler = nil;
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
    
    MLFlattenedItemModel *model = visibleItems[index];
    model.statusDidChangeHandler = nil;
    [visibleItems removeObjectAtIndex:index];
}

- (void)insertFlattenedItems:(NSArray<MLFlattenedItemModel *> *)flattenedItems
                     atIndex:(NSUInteger)index
             intoVisibleItems:(NSMutableArray<MLFlattenedItemModel *> *)visibleItems {
    if (flattenedItems.count == 0 || index > visibleItems.count) {
        return;
    }
    
    NSIndexSet *insertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, flattenedItems.count)];
    [visibleItems insertObjects:flattenedItems atIndexes:insertIndexes];
}

#pragma mark - Action

- (void)appendVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model {
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

- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index {
    if (item == nil) {
        return;
    }
    [self insertRootItems:@[item] atIndex:index];
}

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index {
    if (items.count == 0) {
        return;
    }
    
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSArray<id<MLListItemProtocol>> *oldRootItems = self.rootItems ?: @[];
    NSUInteger insertIndex = MIN(index, oldRootItems.count);
    NSUInteger visibleInsertIndex = visibleItems.count;
    if (insertIndex < oldRootItems.count) {
        NSInteger nextVisibleIndex = [self visibleIndexForObject:oldRootItems[insertIndex] type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
        if (nextVisibleIndex != NSNotFound) {
            visibleInsertIndex = nextVisibleIndex;
        }
    }
    
    NSMutableArray<id<MLListItemProtocol>> *rootItems = [oldRootItems mutableCopy];
    NSIndexSet *rootInsertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertIndex, items.count)];
    [rootItems insertObjects:items atIndexes:rootInsertIndexes];
    _rootItems = [rootItems copy];
    
    NSMutableArray<MLFlattenedItemModel *> *newFlattenedItems = [NSMutableArray array];
    for (id<MLListItemProtocol> item in items) {
        [self appendVisibleItemsForObject:item parent:nil level:0 toArray:newFlattenedItems];
    }
    [self insertFlattenedItems:newFlattenedItems atIndex:visibleInsertIndex intoVisibleItems:visibleItems];
    _visibleItems = [visibleItems copy];
}

- (void)insertRootItem:(id<MLListItemProtocol>)item
              position:(MLListInsertPosition)position {
    if (item == nil) {
        return;
    }
    [self insertRootItems:@[item] position:position];
}

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position {
    NSArray<id<MLListItemProtocol>> *oldRootItems = self.rootItems ?: @[];
    NSUInteger insertIndex = position == MLListInsertPositionFirst ? 0 : oldRootItems.count;
    [self insertRootItems:items atIndex:insertIndex];
}

- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position {
    if (item == nil) {
        return;
    }
    [self insertItems:@[item] toParentItem:parentItem position:position];
}

- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position {
    if (items.count == 0) {
        return;
    }
    if (parentItem == nil) {
        [self insertRootItems:items position:position];
        return;
    }
    
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSInteger parentVisibleIndex = [self visibleIndexForObject:parentItem type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
    if (parentVisibleIndex == NSNotFound) {
        return;
    }
    MLFlattenedItemModel *parentVisibleModel = visibleItems[parentVisibleIndex];
    
    NSMutableArray<id<MLListItemProtocol>> *children = parentItem.children ?: [NSMutableArray array];
    NSArray<id<MLListItemProtocol>> *oldChildren = [children copy];
    NSInteger oldVisibleChildrenCount = MIN(MAX(parentItem.visibleChildrenCount, 0), oldChildren.count);
    NSUInteger insertIndex = position == MLListInsertPositionFirst ? 0 : (NSUInteger)oldVisibleChildrenCount;
    insertIndex = MIN(insertIndex, oldChildren.count);
    
    NSIndexSet *childInsertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertIndex, items.count)];
    [children insertObjects:items atIndexes:childInsertIndexes];
    parentItem.children = children;
    parentItem.totalChildrenCount = MAX(parentItem.totalChildrenCount + (NSInteger)items.count, parentItem.children.count);
    parentItem.visibleChildrenCount = oldVisibleChildrenCount + (NSInteger)items.count;
    parentItem.visibleChildrenCount = MIN(parentItem.visibleChildrenCount, parentItem.children.count);
    
    NSUInteger visibleInsertIndex = visibleItems.count;
    if (position == MLListInsertPositionFirst && oldVisibleChildrenCount > 0 && oldChildren.count > 0) {
        NSInteger firstVisibleChildIndex = [self visibleIndexForObject:oldChildren[0] type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
        if (firstVisibleChildIndex != NSNotFound) {
            visibleInsertIndex = firstVisibleChildIndex;
        }
    } else if (insertIndex < oldVisibleChildrenCount && insertIndex < oldChildren.count) {
        NSInteger nextVisibleIndex = [self visibleIndexForObject:oldChildren[insertIndex] type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
        if (nextVisibleIndex != NSNotFound) {
            visibleInsertIndex = nextVisibleIndex;
        }
    } else {
        NSInteger footerIndex = [self visibleIndexForObject:parentItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
        if (footerIndex != NSNotFound) {
            visibleInsertIndex = footerIndex;
        } else {
            NSRange visibleRange = [self visibleRangeForObject:parentItem inVisibleItems:visibleItems];
            if (visibleRange.location != NSNotFound) {
                visibleInsertIndex = visibleRange.location + visibleRange.length;
            }
        }
    }
    
    NSMutableArray<MLFlattenedItemModel *> *newFlattenedItems = [NSMutableArray array];
    for (id<MLListItemProtocol> item in items) {
        [self appendVisibleItemsForObject:item parent:parentVisibleModel level:parentVisibleModel.level + 1 toArray:newFlattenedItems];
    }
    [self insertFlattenedItems:newFlattenedItems atIndex:visibleInsertIndex intoVisibleItems:visibleItems];
    [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeNormal inVisibleItems:visibleItems];
    [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    
    _visibleItems = [visibleItems copy];
}

- (void)deleteVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model {
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

- (void)collapseVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model {
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
