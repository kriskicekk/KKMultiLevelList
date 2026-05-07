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

@interface MLFlattenedItemSectionController : IGListSectionController

@property (nonatomic, nullable, strong) MLFlattenedItemModel *model;

@property (nonatomic, nullable, weak) id<MLFlattenedItemSectionControllerDelegate> delegate;

- (instancetype)initWithFlattedItemModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemSectionController_h */
