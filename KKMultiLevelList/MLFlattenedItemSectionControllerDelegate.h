//
//  MLFlattenedItemSectionControllerDelegate.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLFlattenedItemSectionControllerDelegate_h
#define MLFlattenedItemSectionControllerDelegate_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MLFlattenedItemSectionController;
@class MLFlattenedItemModel;

/// Internal bridge used by `MLFlattenedItemSectionController`.
///
/// Most consumers should implement `MLManagerDelegate` instead.
@protocol MLFlattenedItemSectionControllerDelegate <NSObject>

@required

/// Returns a cell for the section controller's current flattened model.
- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                                                        cellForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *)model;

/// Returns the size for the section controller's current flattened model.
- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
             sizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *)model;

/// Called when the section controller's item is selected.
- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                didSelectAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model;

@optional

/// Returns custom insets for the section controller's current flattened model.
- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                        insetForItemModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemSectionControllerDelegate_h */
