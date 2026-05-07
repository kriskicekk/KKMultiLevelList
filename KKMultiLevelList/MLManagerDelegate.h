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

@protocol MLManagerDelegate <NSObject>

@required

- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                                                        cellForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *)model;

- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                                                        footerForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *)model;

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
             cellSizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *)model;

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
             footerSizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *)model;

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                didSelectCellAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model;

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
            didSelectFooterAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model;

@optional

- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                        insetForItemModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLManagerDelegate_h */
