//
//  MLDemoFooterCell.m
//  KKMultiLevelList
//
//  Created by Codex on 2026/4/27.
//

#import "MLDemoFooterCell.h"

#import "MLDemoListItem.h"
#import "MLFlattenedItemModel.h"

@interface MLDemoFooterCell ()

@property (nonatomic, strong, readwrite) UIView *containerView;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong, readwrite) UILabel *actionLabel;
@property (nonatomic, strong) UIView *leadingLineView;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation MLDemoFooterCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        
        _containerView = [[UIView alloc] initWithFrame:CGRectZero];
        _containerView.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:_containerView];
        
        _leadingLineView = [[UIView alloc] initWithFrame:CGRectZero];
        _leadingLineView.backgroundColor = [UIColor.tertiaryLabelColor colorWithAlphaComponent:0.55];
        [_containerView addSubview:_leadingLineView];
        
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _loadingIndicator.hidden = YES;
        _loadingIndicator.hidesWhenStopped = YES;
        _loadingIndicator.color = UIColor.tertiaryLabelColor;
        [_containerView addSubview:_loadingIndicator];
        
        _actionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _actionLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        _actionLabel.textColor = UIColor.secondaryLabelColor;
        [_containerView addSubview:_actionLabel];
        
        _arrowImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
        _arrowImageView.tintColor = UIColor.tertiaryLabelColor;
        [_containerView addSubview:_arrowImageView];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.actionLabel.text = nil;
    [self.loadingIndicator stopAnimating];
    self.loadingIndicator.hidden = YES;
    self.leadingLineView.hidden = NO;
    self.arrowImageView.hidden = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.containerView.frame = CGRectInset(self.contentView.bounds, 16.0, 2.0);
    CGFloat centerY = CGRectGetMidY(self.containerView.bounds);
    
    if (self.loadingIndicator.hidden) {
        self.leadingLineView.frame = CGRectMake(16.0, centerY - 0.5, 12.0, 1.0);
        CGFloat labelX = CGRectGetMaxX(self.leadingLineView.frame) + 8.0;
        self.actionLabel.frame = CGRectMake(labelX, 0.0, MIN(180.0, self.containerView.bounds.size.width - labelX - 30.0), self.containerView.bounds.size.height);
    } else {
        self.loadingIndicator.frame = CGRectMake(16.0, centerY - 8.0, 16.0, 16.0);
        CGFloat labelX = CGRectGetMaxX(self.loadingIndicator.frame) + 8.0;
        self.actionLabel.frame = CGRectMake(labelX, 0.0, MIN(180.0, self.containerView.bounds.size.width - labelX - 16.0), self.containerView.bounds.size.height);
    }
    
    self.arrowImageView.frame = CGRectMake(CGRectGetMaxX(self.actionLabel.frame) + 4.0, centerY - 5.0, self.arrowImageView.hidden ? 0.0 : 10.0, 10.0);
}

- (void)configureWithModel:(MLFlattenedItemModel *)model {
    NSInteger remainCount = model.remainingChildrenCount;
    NSString *text = nil;
    if (model.status == MLFlattenedItemStatusLoading) {
        text = @"加载中...";
    } else if (model.status == MLFlattenedItemStatusCollapsing) {
        text = @"折叠中...";
    } else if (model.status == MLFlattenedItemStatusPartiallyExpanded || model.status == MLFlattenedItemStatusCollapsed) {
        text = [NSString stringWithFormat:@"展开剩余 %ld 个子项", (long)remainCount];
    } else if (model.status == MLFlattenedItemStatusFullyExpanded) {
        text = @"折叠";
    } else if (model.status == MLFlattenedItemStatusLoadFailed) {
        text = @"加载失败，请重试！";
    }
    
    self.containerView.backgroundColor = UIColor.clearColor;
    self.containerView.layer.borderWidth = 0.0;
    self.containerView.layer.borderColor = UIColor.clearColor.CGColor;
    self.actionLabel.text = text;
    self.actionLabel.textColor = UIColor.secondaryLabelColor;
    self.loadingIndicator.color = UIColor.tertiaryLabelColor;
    
    if (model.status == MLFlattenedItemStatusLoading || model.status == MLFlattenedItemStatusCollapsing) {
        self.leadingLineView.hidden = YES;
        self.arrowImageView.hidden = YES;
        self.loadingIndicator.hidden = NO;
        self.actionLabel.textColor = UIColor.tertiaryLabelColor;
        [self.loadingIndicator startAnimating];
    } else {
        self.leadingLineView.hidden = NO;
        self.arrowImageView.hidden = NO;
        self.loadingIndicator.hidden = YES;
        [self.loadingIndicator stopAnimating];
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:10.0 weight:UIImageSymbolWeightSemibold];
        NSString *imageName;
        if (model.status == MLFlattenedItemStatusFullyExpanded) {
            imageName = @"chevron.up";
        } else {
            imageName = @"chevron.down";
        }
        self.arrowImageView.image = [[UIImage systemImageNamed:imageName withConfiguration:configuration] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [self setNeedsLayout];
}

@end
