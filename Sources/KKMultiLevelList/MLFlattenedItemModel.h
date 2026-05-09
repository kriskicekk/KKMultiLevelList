//
//  MLFlattenedItemModel.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLFlattenedItemModel_h
#define MLFlattenedItemModel_h

#import "MLListItemState.h"
#import "MLListItemProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// Distinguishes the row generated for the business item from the synthetic
/// footer generated for that same item.
typedef NS_ENUM(NSInteger, MLFlattenedItemType) {
    /// A normal row backed by a business model.
    MLFlattenedItemTypeCell = 0,
    /// A synthetic footer row backed by the same business model as its parent.
    MLFlattenedItemTypeFooter
};

@class MLFlattenedItemModel;

typedef void(^MLFlattenedItemDisplayStatusDidChangeHandler)(MLFlattenedItemModel *model);

/// Flat IGListKit model generated from a tree node.
///
/// One business item may produce two flattened models: a normal row and a
/// footer row. This wrapper snapshots counts and level information so IGListKit
/// can diff UI-facing state independently from the business model object.
@interface MLFlattenedItemModel : NSObject<IGListDiffable>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Parent flattened normal row. Root rows have no parent.
@property (nonatomic, nullable, strong) MLFlattenedItemModel *parent;

/// Business model backing this flattened row.
@property (nonatomic, strong) id<MLListItemProtocol> differableObject;

/// Whether this model represents the normal row or the footer row.
@property (nonatomic, assign) MLFlattenedItemType type;

/// Zero-based tree depth. Root items are level `0`.
@property (nonatomic, assign) NSInteger level;

/// Snapshot of framework-owned state at creation time.
@property (nonatomic, copy) MLListItemState *itemState;

/// Snapshot of the backing item's total child count at creation time.
@property (nonatomic, assign) NSInteger totalChildrenCount;

/// Remaining hidden child count derived from total and visible child counts.
@property (nonatomic, assign, readonly) NSInteger remainingChildrenCount;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemModel_h */
