//
//  MLDemoListItem.h
//  KKMultiLevelList
//
//  Created by Codex on 2026/4/27.
//

#import <Foundation/Foundation.h>

#import "MLListItemProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLDemoListItem : NSObject <MLListItemProtocol>

@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, nullable, strong) NSMutableArray<id<MLListItemProtocol>> *children;
@property (nonatomic, assign) NSInteger totalChildrenCount;
@property (nonatomic, assign) NSInteger visibleChildrenCount;

- (instancetype)initWithItemId:(NSString *)itemId
                         title:(NSString *)title
            totalChildrenCount:(NSInteger)totalChildrenCount;

@end

NS_ASSUME_NONNULL_END
