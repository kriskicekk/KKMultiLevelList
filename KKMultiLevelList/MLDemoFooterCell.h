//
//  MLDemoFooterCell.h
//  KKMultiLevelList
//
//  Created by Codex on 2026/4/27.
//

#import <UIKit/UIKit.h>

@class MLFlattenedItemModel;

NS_ASSUME_NONNULL_BEGIN

@interface MLDemoFooterCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIView *containerView;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong, readonly) UILabel *actionLabel;

- (void)configureWithModel:(MLFlattenedItemModel *)model;

@end

NS_ASSUME_NONNULL_END
