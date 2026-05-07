//
//  MLManagerDelegate.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/27.
//

#ifndef MLManagerDelegate_h
#define MLManagerDelegate_h

@class MLFlattenedItemSectionController;
@class MLFlattenedItemModel;

@protocol MLManagerDelegate <NSObject>

@required

- (nullable __kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nonnull)sectionController
                                                        cellForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *_Nullable)model;

- (nullable __kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nonnull)sectionController
                                                        footerForItemAtIndex:(NSInteger)index
                                                             withItemModel:(MLFlattenedItemModel *_Nullable)model;

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
             cellSizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *_Nonnull)model;

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
             footerSizeForItemAtIndex:(NSInteger)index
                           withItemModel:(MLFlattenedItemModel *_Nonnull)model;

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
                didSelectCellAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *_Nonnull)model;

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
            didSelectFooterAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *_Nonnull)model;

@optional

- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *_Nullable)sectionController
                        insetForItemModel:(MLFlattenedItemModel *_Nonnull)model;

@end

#endif /* MLManagerDelegate_h */
