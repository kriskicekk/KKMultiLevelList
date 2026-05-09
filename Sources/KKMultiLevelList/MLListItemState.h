//
//  MLListItemState.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/5/8.
//

#ifndef MLListItemState_h
#define MLListItemState_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Display status for a list item.
///
/// Normal rows and footer rows both use this status so that business UI can
/// render arrows, loading indicators, retry states, and collapse affordances
/// without keeping duplicate state.
typedef NS_ENUM(NSInteger, MLListItemDisplayStatus) {
    /// Initial fallback state.
    MLListItemDisplayStatusDefault = 0,
    /// No children are visible.
    MLListItemDisplayStatusCollapsed,
    /// Some children are visible, but more remain hidden.
    MLListItemDisplayStatusPartiallyExpanded,
    /// All known children are visible.
    MLListItemDisplayStatusFullyExpanded,
    /// Footer is performing a load/expand action.
    MLListItemDisplayStatusLoading,
    /// Footer is performing a collapse action.
    MLListItemDisplayStatusCollapsing,
    /// Footer action failed and can be retried by business UI.
    MLListItemDisplayStatusLoadFailed
};

/// Framework-owned state for one business item.
///
/// Flattened models carry a snapshot of this state so UI can render expansion,
/// loading, and retry affordances without mutating the business model.
@interface MLListItemState : NSObject<NSCopying>

- (instancetype)initWithVisibleChildrenCount:(NSInteger)visibleChildrenCount
                               displayStatus:(MLListItemDisplayStatus)displayStatus NS_DESIGNATED_INITIALIZER;

/// Number of child rows currently visible for this item.
@property (nonatomic, assign) NSInteger visibleChildrenCount;

/// UI-facing display status for this item.
@property (nonatomic, assign) MLListItemDisplayStatus displayStatus;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListItemState_h */
