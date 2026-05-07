//
//  MLListItemProtocol.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLListItemProtocol_h
#define MLListItemProtocol_h

#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MLListItemProtocol <IGListDiffable>

@property (nonatomic, nullable, strong) NSMutableArray<id<MLListItemProtocol>> *children;

@property (nonatomic, assign) NSInteger totalChildrenCount;

@property (nonatomic, assign) NSInteger visibleChildrenCount;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListItemProtocol_h */
