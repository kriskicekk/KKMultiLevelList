//
//  MLListManager.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLListManager_h
#define MLListManager_h

#import "MLListItemProtocol.h"
#import "MLManagerDelegate.h"
#import "MLListManagerDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface MLListManager : NSObject

@property (nonatomic, strong) IGListAdapter *adapter;

@property (nonatomic, nullable, weak) id<MLManagerDelegate> delegate;

@property (nonatomic, nullable, weak) id<MLListDataSource> dataSource;

- (instancetype)initWithAdapter:(IGListAdapter *)adapter;

- (void)performUpdatesAnimated:(BOOL)animated completion:(nullable IGListUpdaterCompletion)completion;

- (void)reloadObjects:(NSArray *)objects;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListManager_h */
