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
        _usesFooter = NO;
    }
    return self;
}

@end
