//
//  MLFlattenedItemModel.h
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#ifndef MLFlattenedItemModel_h
#define MLFlattenedItemModel_h

#import "MLListItemProtocol.h"

typedef NS_ENUM(NSInteger, MLFlattenedItemType) {
    MLFlattenedItemTypeNormal = 0,
    MLFlattenedItemTypeFooter
};

@interface MLFlattenedItemModel : NSObject<IGListDiffable>

@property (nonatomic, strong) id<MLListItemProtocol> differableObject;

@property (nonatomic, assign) MLFlattenedItemType type;

@property (nonatomic, assign) NSInteger level;

@property (nonatomic, assign, readonly) BOOL isExpaned;

@property (nonatomic, assign, readonly) BOOL isLoading;

- (instancetype)initWithDifferableObject:(id<MLListItemProtocol>)object
                                   level:(NSInteger)level
                                    type:(MLFlattenedItemType)type;

@end

#endif /* MLFlattenedItemModel_h */
