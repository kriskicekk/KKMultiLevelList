//
//  MLListManagerDataSource.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLListManagerDataSource_h
#define MLListManagerDataSource_h

#import "MLListItemProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class MLListManager;

@protocol MLListDataSource <NSObject>

- (nullable UIView *)emptyViewForMLListManager:(MLListManager *)listManager;

- (NSArray<id<MLListItemProtocol>> *)objectsForMLListManager:(MLListManager *)listManager;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListManagerDataSource_h */
