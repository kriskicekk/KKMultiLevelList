//
//  MLListItemProtocol.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLListItemProtocol_h
#define MLListItemProtocol_h

#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

/// The minimal model contract required by `MLListManager`.
///
/// Business models remain the source of truth. The framework reads `children`,
/// `totalChildrenCount`, and `visibleChildrenCount` to build a flat IGListKit
/// data source, while callers keep full control of identity and equality via
/// `IGListDiffable`.
@protocol MLListItemProtocol <IGListDiffable>

/// Child nodes owned by the business model.
///
/// The framework mutates this array when using the insert/delete APIs. Keep the
/// order stable because it is also the order used for flattening.
@property (nonatomic, nullable, strong) NSMutableArray<id<MLListItemProtocol>> *children;

/// Total number of children available for this item.
///
/// This can be greater than `children.count` when the business layer pages data
/// from a remote source. Footer text and expansion state are derived from this
/// value together with `visibleChildrenCount`.
@property (nonatomic, assign) NSInteger totalChildrenCount;

/// Number of child nodes currently visible in the flattened list.
///
/// A value of `0` means collapsed. A value between `0` and
/// `totalChildrenCount` means partially expanded. A value greater than or equal
/// to `totalChildrenCount` means fully expanded.
@property (nonatomic, assign) NSInteger visibleChildrenCount;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListItemProtocol_h */
