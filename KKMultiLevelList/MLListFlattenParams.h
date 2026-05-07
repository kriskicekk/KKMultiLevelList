//
//  MLListFlattenParams.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/28.
//

#ifndef MLListFlattenParams_h
#define MLListFlattenParams_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLListFlattenParams : NSObject

@property (nonatomic, assign) NSInteger expandBatchCount;

@property (nonatomic, assign) BOOL usesFooter;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListFlattenParams_h */
