//
//  MLFlattenedItemModel.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLFlattenedItemModel_h
#define MLFlattenedItemModel_h

#import "MLListItemProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// Presentation state for a flattened item.
///
/// Normal rows and footer rows both use this status so that business UI can
/// render arrows, loading indicators, retry states, and collapse affordances
/// without keeping duplicate state.
typedef NS_ENUM(NSInteger, MLFlattenedItemStatus) {
    /// Initial fallback state.
    MLFlattenedItemStatusDefault = 0,
    /// No children are visible.
    MLFlattenedItemStatusCollapsed,
    /// Some children are visible, but more remain hidden.
    MLFlattenedItemStatusPartiallyExpanded,
    /// All known children are visible.
    MLFlattenedItemStatusFullyExpanded,
    /// Footer is performing a load/expand action.
    MLFlattenedItemStatusLoading,
    /// Footer is performing a collapse action.
    MLFlattenedItemStatusCollapsing,
    /// Footer action failed and can be retried by business UI.
    MLFlattenedItemStatusLoadFailed
};

/// Distinguishes the row generated for the business item from the synthetic
/// footer generated for that same item.
typedef NS_ENUM(NSInteger, MLFlattenedItemType) {
    /// A normal row backed by a business model.
    MLFlattenedItemTypeNormal = 0,
    /// A synthetic footer row backed by the same business model as its parent.
    MLFlattenedItemTypeFooter
};

@class MLFlattenedItemModel;

typedef void(^MLFlattenedItemStatusDidChangeHandler)(MLFlattenedItemModel *model);

/// Flat IGListKit model generated from a tree node.
///
/// One business item may produce two flattened models: a normal row and a
/// footer row. This wrapper snapshots counts and level information so IGListKit
/// can diff UI-facing state independently from the business model object.
@interface MLFlattenedItemModel : NSObject<IGListDiffable>

/// Parent flattened normal row. Root rows have no parent.
@property (nonatomic, nullable, strong) MLFlattenedItemModel *parent;

/// Business model backing this flattened row.
@property (nonatomic, strong) id<MLListItemProtocol> differableObject;

/// Whether this model represents the normal row or the footer row.
@property (nonatomic, assign) MLFlattenedItemType type;

/// Zero-based tree depth. Root items are level `0`.
@property (nonatomic, assign) NSInteger level;

/// Snapshot of the backing item's visible child count at creation time.
@property (nonatomic, assign) NSInteger visibleChildrenCount;

/// Snapshot of the backing item's total child count at creation time.
@property (nonatomic, assign) NSInteger totalChildrenCount;

/// Remaining hidden child count derived from total and visible child counts.
@property (nonatomic, assign, readonly) NSInteger remainingChildrenCount;

/// UI-facing state used by business cells and footer cells.
///
/// Setting this property triggers `statusDidChangeHandler` when the value
/// actually changes.
@property (nonatomic, assign) MLFlattenedItemStatus status;

/// Callback used by the manager to reload this row when only status changes.
@property (nonatomic, nullable, copy) MLFlattenedItemStatusDidChangeHandler statusDidChangeHandler;

/// Creates a flattened model for a business item.
///
/// @param object The business model that conforms to `MLListItemProtocol`.
/// @param parent The parent flattened normal row, or `nil` for root rows.
/// @param level The zero-based tree depth.
/// @param type The row type to generate.
- (instancetype)initWithDifferableObject:(id<MLListItemProtocol>)object
                                  parent:(nullable MLFlattenedItemModel *)parent
                                   level:(NSInteger)level
                                    type:(MLFlattenedItemType)type;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemModel_h */
