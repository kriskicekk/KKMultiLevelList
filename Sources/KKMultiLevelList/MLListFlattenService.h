//
//  MLListFlattenService.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLListFlattenService_h
#define MLListFlattenService_h

#import "MLListItemProtocol.h"
#import "MLFlattenedItemModel.h"
#import "MLListFlattenParams.h"

NS_ASSUME_NONNULL_BEGIN

/// Insertion position for APIs that operate on the currently visible range.
typedef NS_ENUM(NSInteger, MLListInsertPosition) {
    /// Insert before the first currently visible item in the target scope.
    MLListInsertPositionFirst,
    /// Insert after the last currently visible item in the target scope.
    MLListInsertPositionLast,
};

/// Maintains the tree-to-flat projection used by `MLListManager`.
///
/// This class is intentionally UI-agnostic. It owns the current root items,
/// produces `MLFlattenedItemModel` objects for IGListKit, and updates the flat
/// projection when callers expand, collapse, insert, or delete nodes.
@interface MLListFlattenService : NSObject

/// Root tree items used as the source for flattening.
///
/// Assigning this property rebuilds `visibleItems`.
@property (nonatomic, nullable, strong) NSArray<id<MLListItemProtocol>> *rootItems;

/// Flattening configuration.
@property (nonatomic, copy, readonly) MLListFlattenParams *params;

/// Callback assigned to generated flattened models.
///
/// The manager uses this to reload visible rows when UI-only state such as
/// loading changes without a full `performUpdates`.
@property (nonatomic, nullable, copy) MLFlattenedItemDisplayStatusDidChangeHandler displayStatusDidChangeHandler;

/// Current flat list consumed by IGListKit.
@property (nonatomic, strong, readonly) NSArray<MLFlattenedItemModel *> *visibleItems;

/// Creates a flatten service with optional custom configuration.
- (instancetype)initWithParams:(nullable MLListFlattenParams *)params NS_DESIGNATED_INITIALIZER;

/// Creates a flatten service with default configuration.
- (instancetype)init;

/// Expands the backing item of `model` by one batch.
///
/// Pass either the normal model or its footer model. If no more children can be
/// shown, the method is a no-op.
- (void)appendVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model;

/// Inserts one root item at a specific root index.
///
/// Indexes greater than the current root count append to the end.
- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index;

/// Inserts root items at a specific root index while preserving array order.
///
/// Indexes greater than the current root count append to the end.
- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index;

/// Inserts one root item at the beginning or end of the root list.
- (void)insertRootItem:(id<MLListItemProtocol>)item
              position:(MLListInsertPosition)position;

/// Inserts root items at the beginning or end of the root list.
- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position;

/// Inserts one item into a parent item's currently visible child range.
///
/// If `parentItem` is `nil`, the item is inserted into the root list using
/// `position`. If the parent is not currently visible, the method is a no-op.
- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position;

/// Inserts items into a parent item's currently visible child range.
///
/// If `parentItem` is `nil`, the items are inserted into the root list using
/// `position`. If the parent is not currently visible, the method is a no-op.
/// The order of `items` is preserved.
- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position;

/// Deletes the subtree represented by a currently visible flattened model.
///
/// Deleting a child updates its parent's children/count/footer state. Deleting a
/// root item removes it from `rootItems`.
- (void)deleteVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model;

/// Collapses the backing item of `model` by hiding all visible descendants.
- (void)collapseVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListFlattenService_h */
