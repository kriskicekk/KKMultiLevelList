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

typedef NS_ENUM(NSInteger, MLListInsertPosition) {
    MLListInsertPositionFirst,
    MLListInsertPositionLast,
};

@interface MLListFlattenService : NSObject

@property (nonatomic, nullable, strong) NSArray<id<MLListItemProtocol>> *rootItems;

@property (nonatomic, strong) MLListFlattenParams *params;

@property (nonatomic, nullable, copy) MLFlattenedItemStatusDidChangeHandler statusDidChangeHandler;

@property (nonatomic, strong, readonly) NSArray<MLFlattenedItemModel *> *visibleItems;

- (void)appendVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model;

- (void)insertRootItem:(id<MLListItemProtocol>)item
               atIndex:(NSUInteger)index;

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
                atIndex:(NSUInteger)index;

- (void)insertRootItem:(id<MLListItemProtocol>)item
              position:(MLListInsertPosition)position;

- (void)insertRootItems:(NSArray<id<MLListItemProtocol>> *)items
               position:(MLListInsertPosition)position;

- (void)insertItem:(id<MLListItemProtocol>)item
      toParentItem:(nullable id<MLListItemProtocol>)parentItem
          position:(MLListInsertPosition)position;

- (void)insertItems:(NSArray<id<MLListItemProtocol>> *)items
        toParentItem:(nullable id<MLListItemProtocol>)parentItem
            position:(MLListInsertPosition)position;

- (void)deleteVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model;

- (void)collapseVisibleChildenItemsForRootModel:(nullable MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListFlattenService_h */
