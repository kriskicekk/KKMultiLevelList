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

NS_ASSUME_NONNULL_BEGIN

@interface MLListFlattenService : NSObject

@property (nonatomic, nullable, strong) NSArray<id<MLListItemProtocol>> *rootItems;

- (nullable NSArray<MLFlattenedItemModel *> *)getVisibleItems;

NS_ASSUME_NONNULL_END

@end

#endif /* MLListFlattenService_h */
