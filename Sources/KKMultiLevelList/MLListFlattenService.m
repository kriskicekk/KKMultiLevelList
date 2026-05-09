//
//  MLListFlattenService.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLListFlattenService.h"

#import "Internal/MLFlattenedItemModelInternal.h"
#import "Internal/MLListStateStore.h"

static NSString *MLListVisibleModelIndexKey(id<MLListItemProtocol> item, MLFlattenedItemType type) {
    NSCParameterAssert(item);
    id<NSObject> diffIdentifier = [item diffIdentifier];
    NSCAssert(diffIdentifier != nil, @"MLListItemProtocol diffIdentifier must not be nil.");
    if (diffIdentifier == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"%ld-%@", (long)type, diffIdentifier];
}

@interface MLListFlattenService ()

@property (nonatomic, strong) MLListStateStore *stateStore;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *visibleIndexByKey;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MLFlattenedItemModel *> *visibleModelByKey;

@end

@implementation MLListFlattenService

- (instancetype)init {
    return [self initWithParams:nil];
}

- (instancetype)initWithParams:(nullable MLListFlattenParams *)params {
    if (self = [super init]) {
        _params = [params copy] ?: [[MLListFlattenParams alloc] init];
        _stateStore = [[MLListStateStore alloc] init];
        _visibleIndexByKey = [NSMutableDictionary dictionary];
        _visibleModelByKey = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Setter

- (void)setRootItems:(NSMutableArray<id<MLListItemProtocol>> *)rootItems {
    // Keep the business-owned mutable root array. Root insert/delete APIs
    // mutate this same container so the host data source remains synchronized.
    _rootItems = rootItems;
    [self updateVisibleItems:[self visibleItemsForItems:self.rootItems level:0]];
}

- (void)setDisplayStatusDidChangeHandler:(MLFlattenedItemDisplayStatusDidChangeHandler)displayStatusDidChangeHandler {
    _displayStatusDidChangeHandler = [displayStatusDidChangeHandler copy];
    // Existing visible models need the new handler too; newly created models
    // receive it in flattenedItemModelWithObject:parent:level:type:.
    for (MLFlattenedItemModel *model in self.visibleItems) {
        [self installDisplayStatusDidChangeHandlerForModel:model];
    }
}

- (NSArray<MLFlattenedItemModel *> *)visibleItemsForItems:(NSArray<id<MLListItemProtocol>> *)items level:(NSInteger)level {
    NSAssert(level >= 0, @"Flatten level must be non-negative.");
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [NSMutableArray array];
    for (id<MLListItemProtocol> item in items) {
        [self appendVisibleItemsForObject:item parent:nil level:level toArray:visibleItems];
    }
    return [visibleItems copy];
}

- (nullable MLFlattenedItemModel *)visibleModelMatchingModel:(MLFlattenedItemModel *)model {
    NSParameterAssert(model);
    NSString *key = MLListVisibleModelIndexKey(model.differableObject, model.type);
    if (key == nil) {
        return nil;
    }
    return self.visibleModelByKey[key];
}

#pragma mark - Private

- (void)updateVisibleItems:(NSArray<MLFlattenedItemModel *> *)visibleItems {
    _visibleItems = [visibleItems copy] ?: @[];
    [self rebuildVisibleItemLookupTables];
}

- (void)rebuildVisibleItemLookupTables {
    NSMutableDictionary<NSString *, NSNumber *> *visibleIndexByKey = [NSMutableDictionary dictionaryWithCapacity:self.visibleItems.count];
    NSMutableDictionary<NSString *, MLFlattenedItemModel *> *visibleModelByKey = [NSMutableDictionary dictionaryWithCapacity:self.visibleItems.count];
    [self.visibleItems enumerateObjectsUsingBlock:^(MLFlattenedItemModel *model, NSUInteger index, __unused BOOL *stop) {
        NSString *key = MLListVisibleModelIndexKey(model.differableObject, model.type);
        if (key != nil) {
            visibleIndexByKey[key] = @(index);
            visibleModelByKey[key] = model;
        }
    }];
    self.visibleIndexByKey = visibleIndexByKey;
    self.visibleModelByKey = visibleModelByKey;
}

- (void)addLookupEntryForModel:(MLFlattenedItemModel *)model atIndex:(NSUInteger)index {
    NSParameterAssert(model);
    NSString *key = MLListVisibleModelIndexKey(model.differableObject, model.type);
    if (key == nil) {
        return;
    }
    self.visibleIndexByKey[key] = @(index);
    self.visibleModelByKey[key] = model;
}

- (void)removeLookupEntryForModel:(MLFlattenedItemModel *)model {
    NSParameterAssert(model);
    NSString *key = MLListVisibleModelIndexKey(model.differableObject, model.type);
    if (key == nil) {
        return;
    }
    [self.visibleIndexByKey removeObjectForKey:key];
    [self.visibleModelByKey removeObjectForKey:key];
}

- (void)shiftLookupIndexesStartingAtIndex:(NSUInteger)startIndex
                           inVisibleItems:(NSArray<MLFlattenedItemModel *> *)visibleItems
                                    delta:(NSInteger)delta {
    NSParameterAssert(visibleItems);
    if (delta == 0 || startIndex >= visibleItems.count) {
        return;
    }
    for (NSUInteger index = startIndex; index < visibleItems.count; index++) {
        MLFlattenedItemModel *model = visibleItems[index];
        NSString *key = MLListVisibleModelIndexKey(model.differableObject, model.type);
        if (key != nil && self.visibleIndexByKey[key] != nil) {
            self.visibleIndexByKey[key] = @((NSInteger)index + delta);
        }
    }
}

- (void)commitVisibleItems:(NSArray<MLFlattenedItemModel *> *)visibleItems
     replacingVisibleRange:(NSRange)range
                 withItems:(NSArray<MLFlattenedItemModel *> *)replacementItems {
    NSParameterAssert(visibleItems);
    NSParameterAssert(replacementItems);
    NSArray<MLFlattenedItemModel *> *oldVisibleItems = self.visibleItems ?: @[];
    NSAssert(range.location != NSNotFound && NSMaxRange(range) <= oldVisibleItems.count, @"Visible range is out of bounds.");
    if (range.location == NSNotFound || NSMaxRange(range) > oldVisibleItems.count) {
        return;
    }

    NSInteger delta = (NSInteger)replacementItems.count - (NSInteger)range.length;
    NSUInteger suffixCount = oldVisibleItems.count - NSMaxRange(range);
    NSUInteger changedCount = range.length + replacementItems.count;
    NSUInteger indexShiftCount = delta == 0 ? 0 : suffixCount;
    NSUInteger incrementalWork = indexShiftCount + changedCount * 2;
    NSUInteger rebuildWork = visibleItems.count * 2;
    BOOL shouldRebuildLookupTables = incrementalWork >= rebuildWork;
    if (shouldRebuildLookupTables) {
        _visibleItems = [visibleItems copy] ?: @[];
        [self rebuildVisibleItemLookupTables];
        return;
    }

    for (NSUInteger index = range.location; index < NSMaxRange(range); index++) {
        [self removeLookupEntryForModel:oldVisibleItems[index]];
    }

    [self shiftLookupIndexesStartingAtIndex:NSMaxRange(range)
                             inVisibleItems:oldVisibleItems
                                      delta:delta];

    [replacementItems enumerateObjectsUsingBlock:^(MLFlattenedItemModel *model, NSUInteger offset, __unused BOOL *stop) {
        [self addLookupEntryForModel:model atIndex:range.location + offset];
    }];

    _visibleItems = [visibleItems copy] ?: @[];
}

- (MLFlattenedItemModel *)flattenedItemModelWithObject:(id<MLListItemProtocol>)object
                                                parent:(MLFlattenedItemModel *)parent
                                                 level:(NSInteger)level
                                                  type:(MLFlattenedItemType)type {
    NSParameterAssert(object);
    NSInteger visibleChildrenCount = [self visibleChildrenCountForObject:object level:level parent:parent];
    MLFlattenedItemModel *model = [[MLFlattenedItemModel alloc] initWithDifferableObject:object
                                                                                  parent:parent
                                                                                   level:level
                                                                                    type:type
                                                                    visibleChildrenCount:visibleChildrenCount];
    [self installDisplayStatusDidChangeHandlerForModel:model];
    return model;
}

- (void)installDisplayStatusDidChangeHandlerForModel:(MLFlattenedItemModel *)model {
    __weak typeof(self) weakSelf = self;
    model.displayStatusDidChangeHandler = ^(MLFlattenedItemModel *changedModel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (strongSelf.displayStatusDidChangeHandler) {
            strongSelf.displayStatusDidChangeHandler(changedModel);
        }
    };
}

- (NSInteger)initialVisibleChildrenCountForObject:(id<MLListItemProtocol>)object
                                            level:(NSInteger)level
                                       parentItem:(nullable id<MLListItemProtocol>)parentItem {
    NSParameterAssert(object);
    NSInteger visibleChildrenCount = 0;
    if (self.params.defaultVisibleChildrenCountProvider) {
        visibleChildrenCount = self.params.defaultVisibleChildrenCountProvider(object, level, parentItem);
    } else if (self.params.defaultVisibleChildrenCount >= 0) {
        visibleChildrenCount = self.params.defaultVisibleChildrenCount;
    }

    NSArray<id<MLListItemProtocol>> *children = object.children ?: @[];
    return MIN(MAX(visibleChildrenCount, 0), (NSInteger)children.count);
}

- (NSInteger)visibleChildrenCountForObject:(id<MLListItemProtocol>)object
                                      level:(NSInteger)level
                                     parent:(nullable MLFlattenedItemModel *)parent {
    NSParameterAssert(object);
    NSAssert(object.totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");
    NSInteger initialVisibleChildrenCount = [self initialVisibleChildrenCountForObject:object
                                                                                 level:level
                                                                            parentItem:parent.differableObject];
    NSInteger visibleChildrenCount = [self.stateStore visibleChildrenCountForItem:object
                                                      initialVisibleChildrenCount:initialVisibleChildrenCount];
    NSArray<id<MLListItemProtocol>> *children = object.children ?: @[];
    NSInteger clampedVisibleChildrenCount = MIN(MAX(visibleChildrenCount, 0), (NSInteger)children.count);
    if (clampedVisibleChildrenCount != visibleChildrenCount) {
        [self.stateStore setVisibleChildrenCount:clampedVisibleChildrenCount forItem:object];
    }
    return clampedVisibleChildrenCount;
}

- (void)setVisibleChildrenCount:(NSInteger)visibleChildrenCount forObject:(id<MLListItemProtocol>)object {
    NSParameterAssert(object);
    NSArray<id<MLListItemProtocol>> *children = object.children ?: @[];
    NSInteger clampedVisibleChildrenCount = MIN(MAX(visibleChildrenCount, 0), (NSInteger)children.count);
    [self.stateStore setVisibleChildrenCount:clampedVisibleChildrenCount
                                     forItem:object];
}

- (void)appendVisibleItemsForObject:(id<MLListItemProtocol>)object
                             parent:(MLFlattenedItemModel *)parent
                              level:(NSInteger)level
                            toArray:(NSMutableArray<MLFlattenedItemModel *> *)visibleItems {
    NSParameterAssert(object);
    NSParameterAssert(visibleItems);
    NSAssert(level >= 0, @"Flatten level must be non-negative.");
    NSAssert(object.totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");

    // A business item always generates a normal row. It may also generate a
    // footer row after its currently visible descendants.
    MLFlattenedItemModel *cellItem = [self flattenedItemModelWithObject:object
                                                                  parent:parent
                                                                   level:level
                                                                   type:MLFlattenedItemTypeCell];
    [visibleItems addObject:cellItem];
    
    NSArray<id<MLListItemProtocol>> *children = object.children ?: @[];
    NSInteger visibleChildrenCount = MIN(children.count, cellItem.itemState.visibleChildrenCount);
    NSArray<id<MLListItemProtocol>> *visibleChildren = [children subarrayWithRange:NSMakeRange(0, visibleChildrenCount)];
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
    id<MLListItemProtocol> startObject = startModel.differableObject;
    NSInteger endIndex = startIndex + 1;
    while (endIndex < visibleItems.count) {
        MLFlattenedItemModel *currentModel = visibleItems[endIndex];
        // The subtree ends when the next row is not backed by the same object
        // and returns to the same or a shallower level.
        if (currentModel.differableObject != startObject && currentModel.level <= startModel.level) {
            break;
        }
        endIndex++;
    }
    
    return NSMakeRange(startIndex, endIndex - startIndex);
}

- (NSInteger)visibleIndexForObject:(id<MLListItemProtocol>)object
                              type:(MLFlattenedItemType)type {
    NSParameterAssert(object);
    NSAssert(type == MLFlattenedItemTypeCell || type == MLFlattenedItemTypeFooter, @"Flattened item type is invalid.");
    NSString *key = MLListVisibleModelIndexKey(object, type);
    if (key == nil) {
        return NSNotFound;
    }
    NSNumber *index = self.visibleIndexByKey[key];
    return index != nil ? index.integerValue : NSNotFound;
}

- (NSInteger)visibleIndexForObject:(id<MLListItemProtocol>)object
                              type:(MLFlattenedItemType)type
                    inVisibleItems:(NSArray<MLFlattenedItemModel *> *)visibleItems {
    NSParameterAssert(object);
    NSParameterAssert(visibleItems);
    NSAssert(type == MLFlattenedItemTypeCell || type == MLFlattenedItemTypeFooter, @"Flattened item type is invalid.");
    if (visibleItems == self.visibleItems) {
        return [self visibleIndexForObject:object type:type];
    }
    for (NSInteger index = 0; index < visibleItems.count; index++) {
        MLFlattenedItemModel *visibleItem = visibleItems[index];
        if (visibleItem.differableObject == object && visibleItem.type == type) {
            return index;
        }
    }
    return NSNotFound;
}

- (void)replaceVisibleModelForObject:(id<MLListItemProtocol>)object
                                type:(MLFlattenedItemType)type {
    NSParameterAssert(object);
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSInteger index = [self visibleIndexForObject:object type:type];
    if (index == NSNotFound) {
        return;
    }
    
    MLFlattenedItemModel *oldModel = visibleItems[index];
    // Replaced models should no longer be able to request UI reloads.
    oldModel.displayStatusDidChangeHandler = nil;
    MLFlattenedItemModel *newModel = [self flattenedItemModelWithObject:object
                                                                  parent:oldModel.parent
                                                                  level:oldModel.level
                                                                   type:type];
    [visibleItems replaceObjectAtIndex:index withObject:newModel];
    [self commitVisibleItems:visibleItems
       replacingVisibleRange:NSMakeRange(index, 1)
                   withItems:@[newModel]];
}

- (void)removeVisibleModelForObject:(id<MLListItemProtocol>)object
                                type:(MLFlattenedItemType)type {
    NSParameterAssert(object);
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSInteger index = [self visibleIndexForObject:object type:type];
    if (index == NSNotFound) {
        return;
    }
    
    MLFlattenedItemModel *model = visibleItems[index];
    // Removed models may still be retained temporarily by cells or delayed
    // blocks, but they should no longer drive UI updates.
    model.displayStatusDidChangeHandler = nil;
    [visibleItems removeObjectAtIndex:index];
    [self commitVisibleItems:visibleItems
       replacingVisibleRange:NSMakeRange(index, 1)
                   withItems:@[]];
}

- (void)insertFlattenedItems:(NSArray<MLFlattenedItemModel *> *)flattenedItems
                     atIndex:(NSUInteger)index {
    NSParameterAssert(flattenedItems);
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSAssert(index <= visibleItems.count, @"Insert index is out of visibleItems bounds.");
    if (flattenedItems.count == 0 || index > visibleItems.count) {
        return;
    }
    
    NSIndexSet *insertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, flattenedItems.count)];
    [visibleItems insertObjects:flattenedItems atIndexes:insertIndexes];
    [self commitVisibleItems:visibleItems
       replacingVisibleRange:NSMakeRange(index, 0)
                   withItems:flattenedItems];
}

- (void)removeVisibleItemsInRange:(NSRange)range {
    if (range.location == NSNotFound || range.length == 0) {
        return;
    }
    NSMutableArray<MLFlattenedItemModel *> *visibleItems = [_visibleItems mutableCopy] ?: [NSMutableArray array];
    NSAssert(NSMaxRange(range) <= visibleItems.count, @"Remove range is out of visibleItems bounds.");
    if (NSMaxRange(range) > visibleItems.count) {
        return;
    }
    [visibleItems removeObjectsInRange:range];
    [self commitVisibleItems:visibleItems
       replacingVisibleRange:range
                   withItems:@[]];
}

- (void)collapseDescendantsOfObject:(id<MLListItemProtocol>)object {
    NSParameterAssert(object);
    for (id<MLListItemProtocol> child in object.children) {
        [self setVisibleChildrenCount:0 forObject:child];
        [self collapseDescendantsOfObject:child];
    }
}

- (void)removeStateForObjectAndDescendants:(id<MLListItemProtocol>)object {
    NSParameterAssert(object);
    [self.stateStore removeStateForItem:object];
    for (id<MLListItemProtocol> child in object.children) {
        [self removeStateForObjectAndDescendants:child];
    }
}

#pragma mark - Action

- (void)appendVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model {
    if (model == nil) {
        return;
    }
    model = [self visibleModelMatchingModel:model];
    if (model == nil) {
        return;
    }
    
    NSAssert(model.type == MLFlattenedItemTypeCell || model.type == MLFlattenedItemTypeFooter, @"Append expects a normal or footer flattened model.");
    id<MLListItemProtocol> rootItem = model.differableObject;
    NSArray<id<MLListItemProtocol>> *children = rootItem.children ?: @[];
    NSInteger oldVisibleChildrenCount = MIN(MAX(model.itemState.visibleChildrenCount, 0), (NSInteger)children.count);
    NSInteger expandBatchCount = MAX(self.params.expandBatchCount, 1);
    NSInteger newVisibleChildrenCount = self.params.usesFooter ? MIN(oldVisibleChildrenCount + expandBatchCount, (NSInteger)children.count) : (NSInteger)children.count;
    if (newVisibleChildrenCount <= oldVisibleChildrenCount) {
        return;
    }

    NSRange newChildrenRange = NSMakeRange(oldVisibleChildrenCount, newVisibleChildrenCount - oldVisibleChildrenCount);
    NSArray<id<MLListItemProtocol>> *newVisibleChildren = [children subarrayWithRange:newChildrenRange];
    NSMutableArray<MLFlattenedItemModel *> *newFlattenedItems = [NSMutableArray array];
    MLFlattenedItemModel *parentModel = model.type == MLFlattenedItemTypeCell ? model : model.parent;
    NSAssert(parentModel != nil, @"Footer model must keep a parent normal model.");
    if (parentModel == nil) {
        return;
    }
    for (id<MLListItemProtocol> child in newVisibleChildren) {
        [self appendVisibleItemsForObject:child parent:parentModel level:model.level + 1 toArray:newFlattenedItems];
    }
    
    NSInteger footerIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeFooter];
    NSInteger insertIndex = footerIndex;
    if (insertIndex == NSNotFound) {
        NSRange visibleRange = [self visibleRangeForObject:rootItem inVisibleItems:self.visibleItems];
        if (visibleRange.location == NSNotFound) {
            return;
        }
        insertIndex = visibleRange.location + visibleRange.length;
    }
    if (insertIndex > self.visibleItems.count) {
        return;
    }
    
    // Update the framework-owned state first, then replace the affected flattened
    // snapshots so IGListKit can diff the new footer text/display status.
    [self setVisibleChildrenCount:newVisibleChildrenCount forObject:rootItem];
    
    [self insertFlattenedItems:newFlattenedItems atIndex:insertIndex];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeCell];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeFooter];
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
    
    NSMutableArray<id<MLListItemProtocol>> *rootItems = self.rootItems;
    if (rootItems == nil) {
        rootItems = [NSMutableArray array];
        _rootItems = rootItems;
    }
    NSArray<id<MLListItemProtocol>> *oldRootItems = [rootItems copy];
    NSUInteger insertIndex = MIN(index, oldRootItems.count);
    NSUInteger visibleInsertIndex = self.visibleItems.count;
    if (insertIndex < oldRootItems.count) {
        // Insert before the flattened subtree of the root item that currently
        // occupies the target root index.
        NSInteger nextVisibleIndex = [self visibleIndexForObject:oldRootItems[insertIndex] type:MLFlattenedItemTypeCell];
        if (nextVisibleIndex != NSNotFound) {
            visibleInsertIndex = nextVisibleIndex;
        }
    }
    
    NSIndexSet *rootInsertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertIndex, items.count)];
    [rootItems insertObjects:items atIndexes:rootInsertIndexes];
    
    NSMutableArray<MLFlattenedItemModel *> *newFlattenedItems = [NSMutableArray array];
    for (id<MLListItemProtocol> item in items) {
        [self appendVisibleItemsForObject:item parent:nil level:0 toArray:newFlattenedItems];
    }
    [self insertFlattenedItems:newFlattenedItems atIndex:visibleInsertIndex];
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
    
    NSInteger parentVisibleIndex = [self visibleIndexForObject:parentItem type:MLFlattenedItemTypeCell];
    if (parentVisibleIndex == NSNotFound) {
        return;
    }
    MLFlattenedItemModel *parentVisibleModel = self.visibleItems[parentVisibleIndex];
    id<MLListItemProtocol> currentParentItem = parentVisibleModel.differableObject;
    
    NSMutableArray<id<MLListItemProtocol>> *children = currentParentItem.children ?: [NSMutableArray array];
    NSArray<id<MLListItemProtocol>> *oldChildren = [children copy];
    NSAssert(currentParentItem.totalChildrenCount >= 0, @"totalChildrenCount must be non-negative.");
    NSInteger oldVisibleChildrenCount = MIN(MAX(parentVisibleModel.itemState.visibleChildrenCount, 0), oldChildren.count);
    // Child insertions operate on the currently visible range. Inserting at
    // the tail places new rows immediately before the footer.
    NSUInteger insertIndex = position == MLListInsertPositionFirst ? 0 : (NSUInteger)oldVisibleChildrenCount;
    insertIndex = MIN(insertIndex, oldChildren.count);
    
    NSIndexSet *childInsertIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertIndex, items.count)];
    [children insertObjects:items atIndexes:childInsertIndexes];
    currentParentItem.children = children;
    currentParentItem.totalChildrenCount = MAX(currentParentItem.totalChildrenCount + (NSInteger)items.count, currentParentItem.children.count);
    NSInteger newVisibleChildrenCount = MIN(oldVisibleChildrenCount + (NSInteger)items.count, (NSInteger)currentParentItem.children.count);
    [self setVisibleChildrenCount:newVisibleChildrenCount forObject:currentParentItem];
    
    NSUInteger visibleInsertIndex = self.visibleItems.count;
    if (position == MLListInsertPositionFirst && oldVisibleChildrenCount > 0 && oldChildren.count > 0) {
        // First means "before the first currently visible child", not simply
        // after the parent row.
        NSInteger firstVisibleChildIndex = [self visibleIndexForObject:oldChildren[0] type:MLFlattenedItemTypeCell];
        if (firstVisibleChildIndex != NSNotFound) {
            visibleInsertIndex = firstVisibleChildIndex;
        }
    } else if (insertIndex < oldVisibleChildrenCount && insertIndex < oldChildren.count) {
        // When inserting inside the visible range, place new flattened rows
        // before the child that previously lived at that visible index.
        NSInteger nextVisibleIndex = [self visibleIndexForObject:oldChildren[insertIndex] type:MLFlattenedItemTypeCell];
        if (nextVisibleIndex != NSNotFound) {
            visibleInsertIndex = nextVisibleIndex;
        }
    } else {
        // Last means "after the last currently visible child". If a footer
        // exists, the new rows should appear immediately before it.
        NSInteger footerIndex = [self visibleIndexForObject:currentParentItem type:MLFlattenedItemTypeFooter];
        if (footerIndex != NSNotFound) {
            visibleInsertIndex = footerIndex;
        } else {
            NSRange visibleRange = [self visibleRangeForObject:currentParentItem inVisibleItems:self.visibleItems];
            if (visibleRange.location != NSNotFound) {
                visibleInsertIndex = visibleRange.location + visibleRange.length;
            }
        }
    }
    
    NSMutableArray<MLFlattenedItemModel *> *newFlattenedItems = [NSMutableArray array];
    for (id<MLListItemProtocol> item in items) {
        [self appendVisibleItemsForObject:item parent:parentVisibleModel level:parentVisibleModel.level + 1 toArray:newFlattenedItems];
    }
    [self insertFlattenedItems:newFlattenedItems atIndex:visibleInsertIndex];
    [self replaceVisibleModelForObject:currentParentItem type:MLFlattenedItemTypeCell];
    [self replaceVisibleModelForObject:currentParentItem type:MLFlattenedItemTypeFooter];
}

- (void)deleteVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model {
    if (model == nil) {
        return;
    }
    model = [self visibleModelMatchingModel:model];
    if (model == nil) {
        return;
    }
    
    NSAssert(model.type == MLFlattenedItemTypeCell, @"Delete expects a normal flattened model.");
    if (model.type != MLFlattenedItemTypeCell) {
        return;
    }
    id<MLListItemProtocol> deletedItem = model.differableObject;
    NSRange deleteRange = [self visibleRangeForObject:deletedItem inVisibleItems:self.visibleItems];
    if (deleteRange.location == NSNotFound || deleteRange.length == 0) {
        return;
    }
    
    MLFlattenedItemModel *parentModel = model.parent;
    id<MLListItemProtocol> parentItem = parentModel.differableObject;
    NSMutableArray<id<MLListItemProtocol>> *rootItems = self.rootItems;
    
    // Remove the whole visible subtree, not just the tapped row.
    [self removeVisibleItemsInRange:deleteRange];
    [self removeStateForObjectAndDescendants:deletedItem];
    
    if (parentItem != nil) {
        NSUInteger childIndex = [parentItem.children indexOfObjectIdenticalTo:deletedItem];
        if (childIndex != NSNotFound) {
            NSInteger oldVisibleChildrenCount = parentModel.itemState.visibleChildrenCount;
            [parentItem.children removeObjectAtIndex:childIndex];
            parentItem.totalChildrenCount = MAX(parentItem.totalChildrenCount - 1, 0);
            NSInteger newVisibleChildrenCount = oldVisibleChildrenCount;
            if (childIndex < oldVisibleChildrenCount) {
                // Only visible deletions reduce visibleChildrenCount. Deleting
                // a hidden child should keep the visible range unchanged.
                newVisibleChildrenCount = MAX(oldVisibleChildrenCount - 1, 0);
            }
            newVisibleChildrenCount = MIN(newVisibleChildrenCount, (NSInteger)parentItem.children.count);
            [self setVisibleChildrenCount:newVisibleChildrenCount forObject:parentItem];
            [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeCell];
            if (parentItem.children.count == 0 || parentItem.totalChildrenCount <= 0) {
                [self removeVisibleModelForObject:parentItem type:MLFlattenedItemTypeFooter];
            } else {
                [self replaceVisibleModelForObject:parentItem type:MLFlattenedItemTypeFooter];
            }
        }
    } else {
        NSUInteger rootIndex = rootItems == nil ? NSNotFound : [rootItems indexOfObjectIdenticalTo:deletedItem];
        if (rootIndex != NSNotFound) {
            [rootItems removeObjectAtIndex:rootIndex];
        }
    }
}

- (void)collapseVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model {
    if (model == nil) {
        return;
    }
    model = [self visibleModelMatchingModel:model];
    if (model == nil) {
        return;
    }
    
    NSAssert(model.type == MLFlattenedItemTypeCell || model.type == MLFlattenedItemTypeFooter, @"Collapse expects a normal or footer flattened model.");
    id<MLListItemProtocol> rootItem = model.differableObject;
    NSInteger rootIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeCell];
    if (rootIndex == NSNotFound) {
        return;
    }
    
    NSInteger footerIndex = [self visibleIndexForObject:rootItem type:MLFlattenedItemTypeFooter];
    NSRange deleteRange = NSMakeRange(NSNotFound, 0);
    if (footerIndex != NSNotFound) {
        if (footerIndex > rootIndex + 1) {
            // With footer mode, descendants are always between the parent row
            // and the footer row.
            deleteRange = NSMakeRange(rootIndex + 1, footerIndex - rootIndex - 1);
        }
    } else {
        NSRange visibleRange = [self visibleRangeForObject:rootItem inVisibleItems:self.visibleItems];
        if (visibleRange.location != NSNotFound && visibleRange.length > 1) {
            // Without footer mode, collapse removes everything after the parent
            // within the visible subtree.
            deleteRange = NSMakeRange(visibleRange.location + 1, visibleRange.length - 1);
        }
    }
    
    if (deleteRange.location != NSNotFound && deleteRange.length > 0) {
        [self removeVisibleItemsInRange:deleteRange];
    }
    
    [self setVisibleChildrenCount:0 forObject:rootItem];
    if (self.params.collapsesDescendantsOnCollapse) {
        [self collapseDescendantsOfObject:rootItem];
    }
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeCell];
    [self replaceVisibleModelForObject:rootItem type:MLFlattenedItemTypeFooter];
}

@end
