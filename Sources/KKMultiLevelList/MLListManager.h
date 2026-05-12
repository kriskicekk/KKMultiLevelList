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

/// Business data source that supplies the immutable root tree snapshot.
@property (nonatomic, nullable, weak) id<MLListDataSource> dataSource;

/// Service that owns the current tree-to-flat projection.
@property (nonatomic, strong, readonly) MLListFlattenService *flattenService;

/// Whether child expansion controls are rendered as footer rows.
@property (nonatomic, assign, readonly) BOOL usesFooter;

/// Creates a manager with an existing IGListKit adapter.
- (instancetype)initWithAdapter:(IGListAdapter *)adapter;

/// Creates a manager with custom flattening configuration.
- (instancetype)initWithAdapter:(IGListAdapter *)adapter flattenServiceParams:(nullable MLListFlattenParams *)params;

/// Reloads the shared root items from `dataSource` and performs an IGListKit diff update.
- (void)performUpdatesAnimated:(BOOL)animated completion:(nullable IGListUpdaterCompletion)completion;

/// Reloads specific flattened objects without requesting a new data snapshot.
- (void)reloadObjects:(NSArray<id<IGListDiffable>> *)objects;

/// Expands the item represented by `model` by one batch and performs updates.
- (void)appendFlattenItemsWithModel:(MLFlattenedItemModel *)model
                                   animated:(BOOL)animated
                                 completion:(nullable IGListUpdaterCompletion)completion;

/// Updates the visible projection after the business layer inserts one root item.
///
/// Update the data source first; the manager does not mutate root items.
- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index
              animated:(BOOL)animated
            completion:(nullable IGListUpdaterCompletion)completion;

/// Updates the visible projection after the business layer inserts root items.
///
/// Update the data source first; the manager does not mutate root items.
- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index
               animated:(BOOL)animated
             completion:(nullable IGListUpdaterCompletion)completion;

/// Updates the visible projection after the business layer inserts one root item.
- (void)insertRootItem:(id<MLListItemProtocol>)item
              position:(MLListInsertPosition)position
              animated:(BOOL)animated
            completion:(nullable IGListUpdaterCompletion)completion;

/// Updates the visible projection after the business layer inserts root items.
- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position
               animated:(BOOL)animated
             completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts one item into a parent item's currently visible child range.
///
/// Passing `nil` for `parentItem` updates the root-level visible projection.
/// Update the business-owned root data source before calling.
- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position
          animated:(BOOL)animated
        completion:(nullable IGListUpdaterCompletion)completion;

/// Inserts items into a parent item's currently visible child range.
///
/// Passing `nil` for `parentItem` updates the root-level visible projection.
/// Update the business-owned root data source before calling. The order of `items` is
/// preserved for child insertions.
- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position
            animated:(BOOL)animated
          completion:(nullable IGListUpdaterCompletion)completion;

/// Deletes the visible subtree represented by `model`.
///
/// For root models, update the business-owned root data source before calling;
/// the manager removes only the visible projection for that subtree.
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
