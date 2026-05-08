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

@interface MLFlattenedItemModel ()

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
                                    type:(MLFlattenedItemType)type NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemModelInternal_h */
