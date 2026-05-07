//
//  MLFlattenedItemSectionController.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLFlattenedItemSectionController.h"

#import "MLFlattenedItemModel.h"

@implementation MLFlattenedItemSectionController

- (instancetype)initWithFlattedItemModel:(MLFlattenedItemModel *)model {
    if (self = [super init]) {
        _model = model;
    }
    return self;
}

- (NSInteger)numberOfItems {
    return 1;
}

- (CGSize)sizeForItemAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:sizeForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:self sizeForItemAtIndex:index withItemModel:self.model];
    } else {
        return CGSizeZero;
    }
}

- (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:cellForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:self cellForItemAtIndex:index withItemModel:self.model];
    } else {
        return nil;
    }
}

- (void)didSelectItemAtIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:didSelectAtIndex:withItemModel:)]) {
        [self.delegate flattenedItemSectionController:self didSelectAtIndex:index withItemModel:self.model];
    }
}

@end
