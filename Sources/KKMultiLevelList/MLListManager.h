//
//  MLListManager.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLListManager_h
#define MLListManager_h

#import "MLListItemProtocol.h"
#import "MLManagerDelegate.h"
#import "MLListManagerDataSource.h"
#import "MLListFlattenService.h"

NS_ASSUME_NONNULL_BEGIN

@class MLFlattenedItemModel;

/// Coordinates IGListKit with the multi-level flatten service.
///
/// `MLListManager` is the main integration point for applications. It reads
/// business models from `dataSource`, exposes IGListKit objects through its
/// internal adapter data source, and forwards all UI decisions to `delegate`.
@interface MLListManager : NSObject

/// IGListKit adapter managed by this list manager.
@property (nonatomic, strong) IGListAdapter *adapter;

/// Business UI delegate. Cells, sizes, insets, and selection handling live here.
@property (nonatomic, nullable, weak) id<MLManagerDelegate> delegate;

/// Business data source that supplies root tree items.
@property (nonatomic, nullable, weak) id<MLListDataSource> dataSource;

/// Service that owns the current tree-to-flat projection.
@property (nonatomic, strong, readonly) MLListFlattenService *flattenService;

/// Creates a manager with an existing IGListKit adapter.
- (instancetype)initWithAdapter:(IGListAdapter *)adapter;

/// Creates a manager with custom flattening configuration.
- (instancetype)initWithAdapter:(IGListAdapter *)adapter flattenServiceParams:(MLListFlattenParams *)params;

/// Reloads root items from `dataSource` and performs an IGListKit diff update.
- (void)performUpdatesAnimated:(BOOL)animated completion:(nullable IGListUpdaterCompletion)completion;

/// Reloads specific flattened objects without requesting a new data snapshot.
- (void)reloadObjects:(NSArray<id<IGListDiffable>> *)objects;

/// Expands the item represented by `model` by one batch and performs updates.
- (void)appendFlattenItemsWithModel:(MLFlattenedItemModel *)model
                                   animated:(BOOL)animated
                                 completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts one root item at a specific root index.
- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index
              animated:(BOOL)animated
            completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts root items at a specific root index while preserving order.
- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index
               animated:(BOOL)animated
             completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts one root item at the beginning or end of the root list.
- (void)insertRootItem:(id<MLListItemProtocol>)item
              position:(MLListInsertPosition)position
              animated:(BOOL)animated
            completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts root items at the beginning or end of the root list.
- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position
               animated:(BOOL)animated
             completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts one item into a parent item's currently visible child range.
///
/// Passing `nil` for `parentItem` inserts into the root list.
- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position
          animated:(BOOL)animated
        completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts items into a parent item's currently visible child range.
///
/// Passing `nil` for `parentItem` inserts into the root list. The order of
/// `items` is preserved.
- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position
            animated:(BOOL)animated
          completion:(nullable IGListUpdaterCompletion)completion;

/// Deletes the visible subtree represented by `model`.
- (void)deleteFlattenItemsWithModel:(MLFlattenedItemModel *)model
                            animated:(BOOL)animated
                          completion:(nullable IGListUpdaterCompletion)completion;

/// Collapses the visible subtree represented by `model`.
- (void)collapseFlattenItemsWithModel:(MLFlattenedItemModel *)model
                              animated:(BOOL)animated
                            completion:(nullable IGListUpdaterCompletion)completion;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListManager_h */
