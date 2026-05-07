//
//  MLListManager.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLListManager.h"

#import "MLFlattenedItemModel.h"
#import "MLListFlattenService.h"
#import "MLListManagerDataSource.h"
#import "MLFlattenedItemSectionController.h"
#import "MLFlattenedItemSectionControllerDelegate.h"

@interface MLListManager() <IGListAdapterDataSource, MLFlattenedItemSectionControllerDelegate>

@property (nonatomic, nullable, strong) NSMutableArray<MLFlattenedItemModel *> *visibleItems;

@property (nonatomic, nullable, strong) MLListFlattenService *flattenService;

@end

@implementation MLListManager

- (instancetype)initWithAdapter:(IGListAdapter *)adapter {
    if (self = [super init]) {
        _adapter = adapter;
        _adapter.delegate = self;
        _flattenService = [[MLListFlattenService alloc] init];
    }
    return self;
}

#pragma mark - IGListAdapterDataSource

- (nullable UIView *)emptyViewForListAdapter:(nonnull IGListAdapter *)listAdapter {
    return [self.dataSource emptyViewForMLListManager:self];
}

- (nonnull IGListSectionController *)listAdapter:(nonnull IGListAdapter *)listAdapter sectionControllerForObject:(nonnull id)object {
    MLFlattenedItemSectionController *sectionController = [[MLFlattenedItemSectionController alloc] init];
    sectionController.delegate = self;
    return sectionController;
}

- (nonnull NSArray<id<IGListDiffable>> *)objectsForListAdapter:(nonnull IGListAdapter *)listAdapter { 
    return self.visibleItems;
}

#pragma mark - MLFlattenedItemSectionControllerDelegate

- (__kindof UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController cellForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    if (model.type == MLFlattenedItemTypeNormal && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:cellForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController cellForItemAtIndex:index withItemModel:model];
    } else if (model.type == MLFlattenedItemTypeFooter && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:footerForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController footerForItemAtIndex:index withItemModel:model];
    } else {
        return nil;
    }
}

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController sizeForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    if (model.type == MLFlattenedItemTypeNormal && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:cellSizeForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController cellSizeForItemAtIndex:index withItemModel:model];
    } else if (model.type == MLFlattenedItemTypeFooter && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:footerSizeForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:sectionController footerSizeForItemAtIndex:index withItemModel:model];
    } else {
        return CGSizeZero;
    }
}

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController didSelectAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    if (model.type == MLFlattenedItemTypeNormal && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:didSelectCellAtIndex:withItemModel:)]) {
        [self.delegate flattenedItemSectionController:sectionController didSelectCellAtIndex:index withItemModel:model];
    } else if (model.type == MLFlattenedItemTypeFooter && [self.delegate respondsToSelector:@selector(flattenedItemSectionController:didSelectFooterAtIndex:withItemModel:)]) {
        [self.delegate flattenedItemSectionController:sectionController didSelectFooterAtIndex:index withItemModel:model];
    }
}

#pragma mark - Perform Update

- (void)performUpdatesAnimated:(BOOL)animated completion:(nullable IGListUpdaterCompletion)completion {
    self.flattenService.rootItems = [[self.dataSource objectsForMLListManager:self] copy];
    [self reloadVisibleItemsAnimated:animated completion:completion];
}

#pragma mark - Private

- (void)reloadVisibleItemsAnimated:(BOOL)animated completion:(nullable IGListUpdaterCompletion)completion {
    self.visibleItems = [self.flattenService getVisibleItems];
    [self.adapter performUpdatesAnimated:animated completion:completion];
}

@end;
