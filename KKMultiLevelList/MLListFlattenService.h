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

@interface MLListFlattenService : NSObject

@property (nonatomic, nullable, strong) NSArray<id<MLListItemProtocol>> *rootItems;

@property (nonatomic, strong) MLListFlattenParams *params;

@property (nonatomic, nullable, copy) MLFlattenedItemStatusDidChangeHandler statusDidChangeHandler;

@property (nonatomic, strong, readonly) NSArray<MLFlattenedItemModel *> *visibleItems;

- (void)appendVisibleChildenItemsForRootModel:(MLFlattenedItemModel *)model;

- (void)deleteVisibleChildenItemsForRootModel:(MLFlattenedItemModel *)model;

- (void)collapseVisibleChildenItemsForRootModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListFlattenService_h */
