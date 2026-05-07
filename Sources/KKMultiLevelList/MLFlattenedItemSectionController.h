//
//  MLFlattenedItemSectionController.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLFlattenedItemSectionController_h
#define MLFlattenedItemSectionController_h

#import <IGListKit/IGListKit.h>

#import "MLFlattenedItemSectionControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// IGListKit section controller for a single `MLFlattenedItemModel`.
///
/// The section controller is intentionally thin: it stores the current model
/// and delegates cell creation, sizing, selection, and insets back to the
/// manager.
@interface MLFlattenedItemSectionController : IGListSectionController

/// Current flattened model supplied by IGListKit.
@property (nonatomic, nullable, strong) MLFlattenedItemModel *model;

/// Internal delegate that bridges section events back to `MLListManager`.
@property (nonatomic, nullable, weak) id<MLFlattenedItemSectionControllerDelegate> delegate;

/// Designated convenience initializer for tests or manual construction.
- (instancetype)initWithFlattedItemModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemSectionController_h */
