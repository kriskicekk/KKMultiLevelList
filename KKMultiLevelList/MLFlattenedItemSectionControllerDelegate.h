//
//  MLFlattenedItemSectionControllerDelegate.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLFlattenedItemSectionControllerDelegate_h
#define MLFlattenedItemSectionControllerDelegate_h

@class MLFlattenedItemSectionController;
@class MLFlattenedItemModel;

@protocol MLFlattenedItemSectionControllerDelegate <NSObject>

@required

- (nullable __kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nonnull)sectionController
                                                        cellForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *_Nullable)model;

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
             sizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *_Nonnull)model;

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
                didSelectAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *_Nonnull)model;

@optional

- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
                        insetForItemModel:(MLFlattenedItemModel *_Nonnull)model;

@end

#endif /* MLFlattenedItemSectionControllerDelegate_h */
