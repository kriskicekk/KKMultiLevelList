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
@interface MLListManager : NSObject

@property (nonatomic, strong) IGListAdapter *adapter;

@property (nonatomic, nullable, weak) id<MLManagerDelegate> delegate;

@property (nonatomic, nullable, weak) id<MLListDataSource> dataSource;

@property (nonatomic, strong, readonly) MLListFlattenService *flattenService;

- (instancetype)initWithAdapter:(IGListAdapter *)adapter;

- (instancetype)initWithAdapter:(IGListAdapter *)adapter flattenServiceParams:(MLListFlattenParams *)params;

- (void)performUpdatesAnimated:(BOOL)animated completion:(nullable IGListUpdaterCompletion)completion;

- (void)reloadObjects:(NSArray<id<IGListDiffable>> *)objects;

- (void)appendFlattenItemsWithModel:(MLFlattenedItemModel *)model
                                   animated:(BOOL)animated
                                 completion:(nullable IGListUpdaterCompletion)completion;

- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index
              animated:(BOOL)animated
            completion:(nullable IGListUpdaterCompletion)completion;

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index
               animated:(BOOL)animated
             completion:(nullable IGListUpdaterCompletion)completion;

- (void)insertRootItem:(id<MLListItemProtocol>)item
              position:(MLListInsertPosition)position
              animated:(BOOL)animated
            completion:(nullable IGListUpdaterCompletion)completion;

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position
               animated:(BOOL)animated
             completion:(nullable IGListUpdaterCompletion)completion;

- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position
          animated:(BOOL)animated
        completion:(nullable IGListUpdaterCompletion)completion;

- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position
            animated:(BOOL)animated
          completion:(nullable IGListUpdaterCompletion)completion;

- (void)deleteFlattenItemsWithModel:(MLFlattenedItemModel *)model
                            animated:(BOOL)animated
                          completion:(nullable IGListUpdaterCompletion)completion;

- (void)collapseFlattenItemsWithModel:(MLFlattenedItemModel *)model
                              animated:(BOOL)animated
                            completion:(nullable IGListUpdaterCompletion)completion;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListManager_h */
