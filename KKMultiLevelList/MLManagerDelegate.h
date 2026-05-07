//
//  MLManagerDelegate.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/27.
//

#ifndef MLManagerDelegate_h
#define MLManagerDelegate_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MLFlattenedItemSectionController;
@class MLFlattenedItemModel;

/// Provides all business-owned UI for flattened rows.
///
/// `MLListManager` owns tree structure and update operations, while the
/// delegate owns cells, sizes, selection behavior, and layout insets.
@protocol MLManagerDelegate <NSObject>

@required

/// Returns a cell for a normal flattened item.
- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                                                        cellForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *)model;

/// Returns a cell for a synthetic footer item.
- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                                                        footerForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *)model;

/// Returns the size for a normal flattened item.
- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
             cellSizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *)model;

/// Returns the size for a synthetic footer item.
- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
             footerSizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *)model;

/// Called when a normal flattened item is selected.
- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                didSelectCellAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model;

/// Called when a synthetic footer item is selected.
- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
            didSelectFooterAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model;

@optional

/// Returns custom insets for either a normal item or a footer item.
- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                        insetForItemModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLManagerDelegate_h */
