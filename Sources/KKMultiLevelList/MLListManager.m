//
//  MLListManager.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLListManager.h"

#import "MLFlattenedItemModel.h"
#import "MLListFlattenService.h"
#import "MLListFlattenParams.h"
#import "MLListManagerDataSource.h"
#import "MLFlattenedItemSectionController.h"
#import "MLFlattenedItemSectionControllerDelegate.h"

@interface MLListManager() <IGListAdapterDataSource, MLFlattenedItemSectionControllerDelegate>

@property (nonatomic, nullable, strong, readonly) NSArray<MLFlattenedItemModel *> *visibleItems;

@end

@implementation MLListManager

- (instancetype)initWithAdapter:(IGListAdapter *)adapter {
    return [self initWithAdapter:adapter flattenServiceParams:nil];
}

- (instancetype)initWithAdapter:(IGListAdapter *)adapter flattenServiceParams:(nullable MLListFlattenParams *)params {
    NSParameterAssert(adapter);
    if (self = [super init]) {
        _adapter = adapter;
        _adapter.dataSource = self;
        [self setupFlattenServiceWithParams:params];
    }
    return self;
}

- (void)setupFlattenServiceWithParams:(nullable MLListFlattenParams *)params {
    _flattenService = [[MLListFlattenService alloc] initWithParams:params];
    [self setupFlattenServiceDisplayStatusDidChangeHandler];
}

#pragma mark - Getter

- (NSArray<MLFlattenedItemModel *> *)visibleItems {
    return self.flattenService.visibleItems;
}

- (BOOL)usesFooter {
    return self.flattenService.params.usesFooter;
}

#pragma mark - IGListAdapterDataSource

- (nullable UIView *)emptyViewForListAdapter:(nonnull IGListAdapter *)listAdapter {
    return [self.dataSource emptyViewForMLListManager:self];
}

- (nonnull IGListSectionController *)listAdapter:(nonnull IGListAdapter *)listAdapter sectionControllerForObject:(nonnull id)object {
    NSAssert([object isKindOfClass:[MLFlattenedItemModel class]], @"MLListManager only supports MLFlattenedItemModel objects.");
    // Each flattened object is rendered by one one-item section controller.
    MLFlattenedItemSectionController *sectionController = [[MLFlattenedItemSectionController alloc] init];
    sectionController.delegate = self;
    return sectionController;
}

- (nonnull NSArray<id<IGListDiffable>> *)objectsForListAdapter:(nonnull IGListAdapter *)listAdapter {
    // IGListKit consumes the flattened projection, not the original tree.
    return self.visibleItems ?: @[];
}

#pragma mark - MLFlattenedItemSectionControllerDelegate

- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController cellForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    // Keep framework UI-free by forwarding normal rows and footer rows to the
    // business delegate.
    NSAssert(self.delegate != nil, @"MLListManager delegate must be set before rendering cells.");
    if (model.type == MLFlattenedItemTypeCell && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:cellForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController cellForItemAtIndex:index withItemModel:model];
    } else if (model.type == MLFlattenedItemTypeFooter && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:footerForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController footerForItemAtIndex:index withItemModel:model];
    } else {
        return nil;
    }
}

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController sizeForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    NSAssert(self.delegate != nil, @"MLListManager delegate must be set before measuring cells.");
    if (model.type == MLFlattenedItemTypeCell && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:cellSizeForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController cellSizeForItemAtIndex:index withItemModel:model];
    } else if (model.type == MLFlattenedItemTypeFooter && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:footerSizeForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController footerSizeForItemAtIndex:index withItemModel:model];
    } else {
        return CGSizeZero;
    }
}

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController didSelectAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    NSAssert(self.delegate != nil, @"MLListManager delegate must be set before handling selection.");
    if (model.type == MLFlattenedItemTypeCell && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:didSelectCellAtIndex:withItemModel:)]) {
        [self.delegate flattenedItemSectionController:sectionController didSelectCellAtIndex:index withItemModel:model];
    } else if (model.type == MLFlattenedItemTypeFooter && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:didSelectFooterAtIndex:withItemModel:)]) {
        [self.delegate flattenedItemSectionController:sectionController didSelectFooterAtIndex:index withItemModel:model];
    }
}

- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController insetForItemModel:(MLFlattenedItemModel *)model {
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:insetForItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController insetForItemModel:model];
    } else {
        return UIEdgeInsetsZero;
    }
}

#pragma mark - Perform Update

- (void)performUpdatesAnimated:(BOOL)animated completion:(nullable IGListUpdaterCompletion)completion {
    NSAssert(self.dataSource != nil, @"MLListManager dataSource must be set before performing updates.");
    NSArray<id<MLListItemProtocol>> *objects = [self.dataSource objectsForMLListManager:self] ?: @[];
    self.flattenService.rootItems = objects;
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)reloadObjects:(NSArray<id<IGListDiffable>> *)objects {
    NSParameterAssert(objects);
    [self.adapter reloadObjects:objects];
}

#pragma mark - Private

- (void)setupFlattenServiceDisplayStatusDidChangeHandler {
    __weak typeof(self) weakSelf = self;
    self.flattenService.displayStatusDidChangeHandler = ^(MLFlattenedItemModel *changedModel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        
        dispatch_block_t reloadBlock = ^{
            // Display status changes can be triggered by a stale model retained
            // by a cell or delayed block. Always reload the model currently
            // present in visibleItems.
            MLFlattenedItemModel *currentModel = [strongSelf currentVisibleModelMatchingModel:changedModel];
            if (currentModel != nil) {
                [strongSelf reloadObjects:@[currentModel]];
            }
        };
        
        if ([NSThread isMainThread]) {
            reloadBlock();
        } else {
            dispatch_async(dispatch_get_main_queue(), reloadBlock);
        }
    };
}

- (nullable MLFlattenedItemModel *)currentVisibleModelMatchingModel:(MLFlattenedItemModel *)model {
    NSParameterAssert(model);
    return [self.flattenService visibleModelMatchingModel:model];
}
    
- (void)appendFlattenItemsWithModel:(MLFlattenedItemModel *)model
                           animated:(BOOL)animated
                         completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(model);
    MLFlattenedItemModel *currentModel = [self currentVisibleModelMatchingModel:model];
    if (currentModel == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    // Structural changes update visibleItems first, then ask IGListKit to diff
    // the old and new flattened projections.
    [self.flattenService appendVisibleChildenItemsForRootModel:currentModel];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index
              animated:(BOOL)animated
            completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(item);
    [self.flattenService insertRootItem:item atIndex:index];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index
               animated:(BOOL)animated
             completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(items);
    [self.flattenService insertRootItems:items atIndex:index];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)insertRootItem:(id<MLListItemProtocol>)item
              position:(MLListInsertPosition)position
              animated:(BOOL)animated
            completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(item);
    [self.flattenService insertRootItem:item position:position];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position
               animated:(BOOL)animated
             completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(items);
    [self.flattenService insertRootItems:items position:position];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position
          animated:(BOOL)animated
        completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(item);
    [self.flattenService insertItem:item toParentItem:parentItem position:position];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position
            animated:(BOOL)animated
          completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(items);
    [self.flattenService insertItems:items toParentItem:parentItem position:position];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)deleteFlattenItemsWithModel:(MLFlattenedItemModel *)model
                            animated:(BOOL)animated
                          completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(model);
    MLFlattenedItemModel *currentModel = [self currentVisibleModelMatchingModel:model];
    if (currentModel == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    [self.flattenService deleteVisibleChildenItemsForRootModel:currentModel];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

- (void)collapseFlattenItemsWithModel:(MLFlattenedItemModel *)model
                              animated:(BOOL)animated
                            completion:(IGListUpdaterCompletion)completion {
    NSParameterAssert(model);
    MLFlattenedItemModel *currentModel = [self currentVisibleModelMatchingModel:model];
    if (currentModel == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    [self.flattenService collapseVisibleChildenItemsForRootModel:currentModel];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

@end
