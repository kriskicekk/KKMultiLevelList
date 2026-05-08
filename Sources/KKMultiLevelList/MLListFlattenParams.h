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

/// Configuration used when converting tree data into flat list data.
@interface MLListFlattenParams : NSObject <NSCopying>

/// Number of additional children revealed by one expand action.
///
/// Values less than `1` are treated as `1` by the flatten service.
@property (nonatomic, assign) NSInteger expandBatchCount;

/// Whether the service should generate a footer item for nodes with children.
///
/// When enabled, footers can be used by the business layer to render
/// "load more", "collapse", loading, or retry UI.
@property (nonatomic, assign) BOOL usesFooter;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListFlattenParams_h */
