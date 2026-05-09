//
//  MLListStateStore.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/5/8.
//

#ifndef MLListStateStore_h
#define MLListStateStore_h

#import "MLListItemProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLListStateStore : NSObject

/// Returns the stored visible child count for `item`, seeding it with the
/// provided initial count when the item has no stored state yet.
- (NSInteger)visibleChildrenCountForItem:(id<MLListItemProtocol>)item
              initialVisibleChildrenCount:(NSInteger)initialVisibleChildrenCount;

/// Stores the visible child count for `item`.
- (void)setVisibleChildrenCount:(NSInteger)visibleChildrenCount
                        forItem:(id<MLListItemProtocol>)item;

/// Removes the stored visible child count for `item`.
- (void)removeStateForItem:(id<MLListItemProtocol>)item;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListStateStore_h */
