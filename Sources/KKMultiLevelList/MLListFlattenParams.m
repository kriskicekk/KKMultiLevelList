//
//  MLListFlattenParams.m
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/28.
//

#import "MLListFlattenParams.h"

@implementation MLListFlattenParams

- (instancetype)init {
    if (self = [super init]) {
        _expandBatchCount = 5;
        _defaultVisibleChildrenCount = 0;
        _usesFooter = YES;
        _collapsesDescendantsOnCollapse = NO;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MLListFlattenParams *params = [[[self class] allocWithZone:zone] init];
    params.expandBatchCount = self.expandBatchCount;
    params.defaultVisibleChildrenCount = self.defaultVisibleChildrenCount;
    params.defaultVisibleChildrenCountProvider = self.defaultVisibleChildrenCountProvider;
    params.usesFooter = self.usesFooter;
    params.collapsesDescendantsOnCollapse = self.collapsesDescendantsOnCollapse;
    return params;
}

@end
