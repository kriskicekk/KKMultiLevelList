//
//  MLDemoTitleCell.h
//  KKMultiLevelList
//
//  Created by Codex on 2026/4/27.
//

#import <UIKit/UIKit.h>

@class MLFlattenedItemModel;

NS_ASSUME_NONNULL_BEGIN

@interface MLDemoTitleCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIView *cardView;
@property (nonatomic, strong, readonly) UILabel *arrowLabel;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIView *separatorView;

- (void)configureWithModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END
