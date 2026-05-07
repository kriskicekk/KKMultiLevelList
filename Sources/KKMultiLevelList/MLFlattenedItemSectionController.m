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
    NSParameterAssert(model);
    if (self = [super init]) {
        _model = model;
    }
    return self;
}

- (void)didUpdateToObject:(id)object {
    NSAssert([object isKindOfClass:[MLFlattenedItemModel class]], @"Section object must be MLFlattenedItemModel.");
    if ([object isKindOfClass:[MLFlattenedItemModel class]]) {
        // IGListKit may reuse the section controller for a new equal-identity
        // object. Always keep the latest model snapshot.
        self.model = object;
    }
}

- (NSInteger)numberOfItems {
    return 1;
}

- (UIEdgeInsets)inset {
    NSAssert(self.model != nil, @"Section controller model must be set before asking for inset.");
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:insetForItemModel:)]) {
        return [self.delegate flattenedItemSectionController:self insetForItemModel:self.model];
    } else {
        return UIEdgeInsetsZero;
    }
}

- (CGSize)sizeForItemAtIndex:(NSInteger)index {
    NSAssert(index == 0, @"MLFlattenedItemSectionController only renders one item.");
    NSAssert(self.model != nil, @"Section controller model must be set before measuring.");
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:sizeForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:self sizeForItemAtIndex:index withItemModel:self.model];
    } else {
        return CGSizeZero;
    }
}

- (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index {
    NSAssert(index == 0, @"MLFlattenedItemSectionController only renders one item.");
    NSAssert(self.model != nil, @"Section controller model must be set before creating cells.");
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:cellForItemAtIndex:withItemModel:)]) {
        return [self.delegate flattenedItemSectionController:self cellForItemAtIndex:index withItemModel:self.model];
    } else {
        return nil;
    }
}

- (void)didSelectItemAtIndex:(NSInteger)index {
    NSAssert(index == 0, @"MLFlattenedItemSectionController only renders one item.");
    NSAssert(self.model != nil, @"Section controller model must be set before handling selection.");
    if ([self.delegate respondsToSelector:@selector(flattenedItemSectionController:didSelectAtIndex:withItemModel:)]) {
        [self.delegate flattenedItemSectionController:self didSelectAtIndex:index withItemModel:self.model];
    }
}

@end
