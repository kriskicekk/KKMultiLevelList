//
//  MLFlattenedItemModel.m
//  KKMutilLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "MLFlattenedItemModel.h"
#import "MLListItemProtocol.h"

@implementation MLFlattenedItemModel

- (instancetype)initWithDifferableObject:(id<MLListItemProtocol>)object
                                   level:(NSInteger)level
                                    type:(MLFlattenedItemType)type {
    if (self = [super init]) {
        _differableObject = object;
        _type = type;
    }
    return self;
}

#pragma mark - IGListDiffable

-(id<NSObject>)diffIdentifier {
    return [self.differableObject diffIdentifier];
}

-(BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object {
    if (self == object) {
        return YES;
    }
    
    if (![(id)object isKindOfClass:[MLFlattenedItemModel class]]) {
        return NO;
    }
    
    MLFlattenedItemModel *model = (MLFlattenedItemModel *)object;
    
    return [self.differableObject isEqualToDiffableObject:object]
        && model.type == self.type
        && model.level == self.level;
}

@end
