//
//  MLDemoTitleCell.m
//  KKMultiLevelList
//
//  Created by Codex on 2026/4/27.
//

#import "MLDemoTitleCell.h"

#import "MLDemoListItem.h"
#import "MLFlattenedItemModel.h"

@interface MLDemoTitleCell ()

@property (nonatomic, strong, readwrite) UIView *cardView;
@property (nonatomic, strong, readwrite) UILabel *arrowLabel;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIView *separatorView;
@property (nonatomic, nullable, strong, readwrite) MLFlattenedItemModel *model;
@property (nonatomic, strong) NSLayoutConstraint *arrowWidthConstraint;

@end

@implementation MLDemoTitleCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = UIColor.clearColor;
        
        _cardView = [[UIView alloc] initWithFrame:CGRectZero];
        _cardView.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:_cardView];
        
        _arrowLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _arrowLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
        _arrowLabel.textAlignment = NSTextAlignmentCenter;
        _arrowLabel.textColor = UIColor.tertiaryLabelColor;
        [_cardView addSubview:_arrowLabel];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
        _titleLabel.textColor = UIColor.labelColor;
        [_cardView addSubview:_titleLabel];
        
        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _separatorView.backgroundColor = [UIColor.labelColor colorWithAlphaComponent:0.05];
        [_cardView addSubview:_separatorView];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.arrowLabel.text = nil;
    self.titleLabel.text = nil;
    self.arrowLabel.hidden = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.cardView.frame = CGRectInset(self.contentView.bounds, 16.0, 2.0);
    
    CGFloat arrowWidth = self.arrowLabel.hidden ? 0.0 : 16.0;
    CGFloat titleX = 16.0;
    self.titleLabel.frame = CGRectMake(titleX, 0.0, self.cardView.bounds.size.width - titleX - 16.0 - arrowWidth, self.cardView.bounds.size.height);
    self.arrowLabel.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame) - 4.0, 0.0, arrowWidth, self.cardView.bounds.size.height);
    self.separatorView.frame = CGRectMake(16.0, self.cardView.bounds.size.height - 1.0, self.cardView.bounds.size.width - 32.0, 1.0);
}

- (void)configureWithModel:(MLFlattenedItemModel *)model {
    self.model = model;
    MLDemoListItem *item = (MLDemoListItem *)model.differableObject;
    BOOL hasChildren = model.totalChildrenCount > 0;
    CGFloat alpha = model.level == 0 ? 0.95 : (model.level == 1 ? 0.82 : 0.72);
    
    self.arrowLabel.hidden = !hasChildren;
    NSString *text;
    if (model.status == MLFlattenedItemStatusPartiallyExpanded || model.status == MLFlattenedItemStatusFullyExpanded) {
        text = @"⌄";
    } else {
        text = @"›";
    }
    self.arrowLabel.text = text;
    self.arrowLabel.textColor = hasChildren ? UIColor.tertiaryLabelColor : UIColor.clearColor;
    self.titleLabel.textColor = [UIColor.labelColor colorWithAlphaComponent:alpha];
    self.titleLabel.font = model.level == 0
        ? [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium]
        : [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    self.cardView.backgroundColor = UIColor.clearColor;
    self.cardView.layer.borderWidth = 0.0;
    self.cardView.layer.borderColor = UIColor.clearColor.CGColor;
    self.cardView.layer.cornerRadius = 0.0;
    self.separatorView.hidden = NO;
    self.separatorView.backgroundColor = [UIColor.labelColor colorWithAlphaComponent:model.level == 0 ? 0.06 : 0.04];
    self.titleLabel.text = item.title;
    [self setNeedsLayout];
}

@end
