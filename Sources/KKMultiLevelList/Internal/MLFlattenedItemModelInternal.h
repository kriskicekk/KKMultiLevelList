//
//  MLFlattenedItemModelInternal.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/5/8.
//

#ifndef MLFlattenedItemModelInternal_h
#define MLFlattenedItemModelInternal_h

#import "MLFlattenedItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLListItemState ()

/// Callback used by the owning flattened model when only display status changes.
@property (nonatomic, nullable, copy) void (^displayStatusDidChangeHandler)(MLListItemState *state);

@end

@interface MLFlattenedItemModel ()

/// Callback used by the manager to reload this row when only display status changes.
@property (nonatomic, nullable, copy) MLFlattenedItemDisplayStatusDidChangeHandler displayStatusDidChangeHandler;

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

/// Creates a flattened model with framework-owned state snapshots.
///
/// @param visibleChildrenCount Snapshot of currently visible children.
- (instancetype)initWithDifferableObject:(id<MLListItemProtocol>)object
                                  parent:(nullable MLFlattenedItemModel *)parent
                                   level:(NSInteger)level
                                    type:(MLFlattenedItemType)type
                    visibleChildrenCount:(NSInteger)visibleChildrenCount
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemModelInternal_h */
