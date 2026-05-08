//
//  MLListFlattenService.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLListFlattenService.h"

@implementation MLListFlattenService

- (instancetype)init {
    return [self initWithParams:nil];
}

- (instancetype)initWithParams:(nullable MLListFlattenParams *)params {
    if (self = [super init]) {
        _params = [params copy] ?: [[MLListFlattenParams alloc] init];
    }
    return self;
}

#pragma mark - Setter

- (void)setRootItems:(NSArray<id<MLListItemProtocol>> *)rootItems {
    // Replacing root items establishes a new tree snapshot and rebuilds the
    // visible projection from scratch.
    _rootItems = rootItems;
    _visibleItems = [self visibleItemsForItems:self.rootItems level:0];
}

- (void)setStatusDidChangeHandler:(MLFlattenedItemStatusDidChangeHandler)statusDidChangeHandler {
    _statusDidChangeHandler = [statusDidChangeHandler copy];
    // Existing visible models need the new handler too; newly created models
    // receive it in flattenedItemModelWithObject:parent:level:type:.
    for (MLFlattenedItemModel *model in self.visibleItems) {
        model.statusDidChangeHandler = _statusDidChangeHandler;
    }
}

- (void)reloadVisibleItems {
    _visibleItems = [self visibleItemsForItems:self.rootItems level:0];
}

- (NSArray<MLFlattenedItemModel *> *)visibleItemsForItems:(NSArray<id<MLListItemProtocol>> *)items level:(NSInteger)level {
    NSAssert(level >= 0, @"Flatten level must be non-negative.");
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
    NSParameterAssert(object);
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
    NSParameterAssert(object);
    NSParameterAssert(visibleItems);
    NSAssert(level >= 0, @"Flatten level must be non-negative.");
    NSAssert(object.visibleChildrenCount >= 0, @"visibleChildrenCount must be non-negative.");
    NSAssert(object.totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");

    // A business item always generates a normal row. It may also generate a
    // footer row after its currently visible descendants.
    MLFlattenedItemModel *cellItem = [self flattenedItemModelWithObject:object
                                                                  parent:parent
                                                                   level:level
                                                                    type:MLFlattenedItemTypeCell];
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
    NSParameterAssert(object);
    NSParameterAssert(visibleItems);
    NSInteger startIndex = [self visibleIndexForObject:object type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
    if (startIndex == NSNotFound) {
        return NSMakeRange(NSNotFound, 0);
    }
    
    MLFlattenedItemModel *startModel = visibleItems[startIndex];
    NSInteger endIndex = startIndex + 1;
    while (endIndex < visibleItems.count) {
        MLFlattenedItemModel *currentModel = visibleItems[endIndex];
        // The subtree ends when the next row is not backed by the same object
        // and returns to the same or a shallower level.
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
    NSParameterAssert(object);
    NSParameterAssert(visibleItems);
    NSAssert(type == MLFlattenedItemTypeCell || type == MLFlattenedItemTypeFooter, @"Flattened item type is invalid.");
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
    NSParameterAssert(object);
    NSParameterAssert(visibleItems);
    NSInteger index = [self visibleIndexForObject:object type:type inVisibleItems:visibleItems];
    if (index == NSNotFound) {
        return;
    }
    
    MLFlattenedItemModel *oldModel = visibleItems[index];
    // Replaced models should no longer be able to request UI reloads.
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
    NSParameterAssert(object);
    NSParameterAssert(visibleItems);
    NSInteger index = [self visibleIndexForObject:object type:type inVisibleItems:visibleItems];
    if (index == NSNotFound) {
        return;
    }
    
    MLFlattenedItemModel *model = visibleItems[index];
    // Removed models may still be retained temporarily by cells or delayed
    // blocks, but they should no longer drive UI updates.
    model.statusDidChangeHandler = nil;
    [visibleItems removeObjectAtIndex:index];
}

- (void)insertFlattenedItems:(NSArray<MLFlattenedItemModel *> *)flattenedItems
                     atIndex:(NSUInteger)index
             intoVisibleItems:(NSMutableArray<MLFlattenedItemModel *> *)visibleItems {
    NSParameterAssert(flattenedItems);
    NSParameterAssert(visibleItems);
    NSAssert(index <= visibleItems.count, @"Insert index is out of visibleItems bounds.");
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
    
    NSAssert(model.type == MLFlattenedItemTypeCell || model.type == MLFlattenedItemTypeFooter, @"Append expects a normal or footer flattened model.");
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
    MLFlattenedItemModel *parentModel = model.type == MLFlattenedItemTypeCell ? model : model.parent;
    NSAssert(parentModel != nil, @"Footer model must keep a parent normal model.");
    if (parentModel == nil) {
        return;
    }
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
    
    // Update the business model first, then replace the affected flattened
    // snapshots so IGListKit can diff the new footer text/status.
    rootItem.visibleChildrenCount = newVisibleChildrenCount;
    
    NSIndexSet *insertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertIndex, newFlattenedItems.count)];
    [visibleItems insertObjects:newFlattenedItems atIndexes:insertIndexes];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    
    _visibleItems = [visibleItems copy];
}

- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index {
    NSParameterAssert(item);
    if (item == nil) {
        return;
    }
    [self insertRootItems:@[item] atIndex:index];
}

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index {
    NSParameterAssert(items);
    if (items.count == 0) {
        return;
    }
    
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSArray<id<MLListItemProtocol>> *oldRootItems = self.rootItems ?: @[];
    NSUInteger insertIndex = MIN(index, oldRootItems.count);
    NSUInteger visibleInsertIndex = visibleItems.count;
    if (insertIndex < oldRootItems.count) {
        // Insert before the flattened subtree of the root item that currently
        // occupies the target root index.
        NSInteger nextVisibleIndex = [self visibleIndexForObject:oldRootItems[insertIndex] type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
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
    NSParameterAssert(item);
    if (item == nil) {
        return;
    }
    [self insertRootItems:@[item] position:position];
}

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position {
    NSParameterAssert(items);
    NSArray<id<MLListItemProtocol>> *oldRootItems = self.rootItems ?: @[];
    NSUInteger insertIndex = position == MLListInsertPositionFirst ? 0 : oldRootItems.count;
    [self insertRootItems:items atIndex:insertIndex];
}

- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position {
    NSParameterAssert(item);
    if (item == nil) {
        return;
    }
    [self insertItems:@[item] toParentItem:parentItem position:position];
}

- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position {
    NSParameterAssert(items);
    if (items.count == 0) {
        return;
    }
    if (parentItem == nil) {
        [self insertRootItems:items position:position];
        return;
    }
    
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSInteger parentVisibleIndex = [self visibleIndexForObject:parentItem type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
    if (parentVisibleIndex == NSNotFound) {
        return;
    }
    MLFlattenedItemModel *parentVisibleModel = visibleItems[parentVisibleIndex];
    
    NSMutableArray<id<MLListItemProtocol>> *children = parentItem.children ?: [NSMutableArray array];
    NSArray<id<MLListItemProtocol>> *oldChildren = [children copy];
    NSAssert(parentItem.visibleChildrenCount >= 0, @"visibleChildrenCount must be non-negative.");
    NSAssert(parentItem.totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");
    NSInteger oldVisibleChildrenCount = MIN(MAX(parentItem.visibleChildrenCount, 0), oldChildren.count);
    // Child insertions operate on the currently visible range. Inserting at
    // the tail places new rows immediately before the footer.
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
        // First means "before the first currently visible child", not simply
        // after the parent row.
        NSInteger firstVisibleChildIndex = [self visibleIndexForObject:oldChildren[0] type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
        if (firstVisibleChildIndex != NSNotFound) {
            visibleInsertIndex = firstVisibleChildIndex;
        }
    } else if (insertIndex < oldVisibleChildrenCount && insertIndex < oldChildren.count) {
        // When inserting inside the visible range, place new flattened rows
        // before the child that previously lived at that visible index.
        NSInteger nextVisibleIndex = [self visibleIndexForObject:oldChildren[insertIndex] type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
        if (nextVisibleIndex != NSNotFound) {
            visibleInsertIndex = nextVisibleIndex;
        }
    } else {
        // Last means "after the last currently visible child". If a footer
        // exists, the new rows should appear immediately before it.
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
    [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
    [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    
    _visibleItems = [visibleItems copy];
}

- (void)deleteVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model {
    if (model == nil) {
        return;
    }
    
    NSAssert(model.type == MLFlattenedItemTypeCell, @"Delete expects a normal flattened model.");
    if (model.type != MLFlattenedItemTypeCell) {
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
    
    // Remove the whole visible subtree, not just the tapped row.
    [visibleItems removeObjectsInRange:deleteRange];
    
    if (parentItem != nil) {
        NSUInteger childIndex = [parentItem.children indexOfObjectIdenticalTo:deletedItem];
        if (childIndex != NSNotFound) {
            NSInteger oldVisibleChildrenCount = parentItem.visibleChildrenCount;
            [parentItem.children removeObjectAtIndex:childIndex];
            parentItem.totalChildrenCount = MAX(parentItem.totalChildrenCount - 1, 0);
            if (childIndex < oldVisibleChildrenCount) {
                // Only visible deletions reduce visibleChildrenCount. Deleting
                // a hidden child should keep the visible range unchanged.
                parentItem.visibleChildrenCount = MAX(oldVisibleChildrenCount - 1, 0);
            }
            parentItem.visibleChildrenCount = MIN(parentItem.visibleChildrenCount, parentItem.children.count);
            [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
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
    
    NSAssert(model.type == MLFlattenedItemTypeCell || model.type == MLFlattenedItemTypeFooter, @"Collapse expects a normal or footer flattened model.");
    id<MLListItemProtocol> rootItem = model.differableObject;
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSInteger rootIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
    if (rootIndex == NSNotFound) {
        return;
    }
    
    NSInteger footerIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    NSRange deleteRange = NSMakeRange(NSNotFound, 0);
    if (footerIndex != NSNotFound) {
        if (footerIndex > rootIndex + 1) {
            // With footer mode, descendants are always between the parent row
            // and the footer row.
            deleteRange = NSMakeRange(rootIndex + 1, footerIndex - rootIndex - 1);
        }
    } else {
        NSRange visibleRange = [self visibleRangeForObject:rootItem inVisibleItems:visibleItems];
        if (visibleRange.location != NSNotFound && visibleRange.length > 1) {
            // Without footer mode, collapse removes everything after the parent
            // within the visible subtree.
            deleteRange = NSMakeRange(visibleRange.location + 1, visibleRange.length - 1);
        }
    }
    
    if (deleteRange.location != NSNotFound && deleteRange.length > 0) {
        [visibleItems removeObjectsInRange:deleteRange];
    }
    
    rootItem.visibleChildrenCount = 0;
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeCell inVisibleItems:visibleItems];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeFooter inVisibleItems:visibleItems];
    
    _visibleItems = [visibleItems copy];
}

@end
