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

@protocol MLFlattenedItemSectionControllerDelegate <NSObject>

@required

- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                                                        cellForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *)model;

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
             sizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *)model;

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                didSelectAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model;

@optional

- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController
                        insetForItemModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END

#endif /* MLFlattenedItemSectionControllerDelegate_h */
