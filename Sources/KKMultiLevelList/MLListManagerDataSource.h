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

/// Supplies root items and empty-state UI to `MLListManager`.
@protocol MLListDataSource <NSObject>

/// Returns the view displayed by IGListKit when there are no objects.
- (nullable UIView *)emptyViewForMLListManager:(MLListManager *)listManager;

/// Returns the current immutable root tree snapshot.
///
/// The business layer remains the source of truth for root insertions and
/// deletions. Update your own data source first, then ask `MLListManager` to
/// perform updates so it can read a fresh snapshot.
- (NSArray<id<MLListItemProtocol>> *)objectsForMLListManager:(MLListManager *)listManager;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListManagerDataSource_h */
