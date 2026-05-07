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

/// Returns the current root tree items.
///
/// The manager reads this during `performUpdatesAnimated:completion:` and then
/// asks the flatten service to build visible flattened models.
- (NSArray<id<MLListItemProtocol>> *)objectsForMLListManager:(MLListManager *)listManager;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListManagerDataSource_h */
