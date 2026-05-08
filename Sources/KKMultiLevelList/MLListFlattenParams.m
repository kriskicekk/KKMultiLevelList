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
        _usesFooter = YES;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MLListFlattenParams *params = [[[self class] allocWithZone:zone] init];
    params.expandBatchCount = self.expandBatchCount;
    params.usesFooter = self.usesFooter;
    return params;
}

@end
