//
//  ViewController.m
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/26.
//

#import "ViewController.h"

#import <IGListKit/IGListKit.h>

#import "MLDemoFooterCell.h"
#import "MLDemoListItem.h"
#import "MLDemoTitleCell.h"
#import "MLFlattenedItemModel.h"
#import "MLFlattenedItemSectionController.h"
#import "MLListManager.h"

static NSInteger const kDemoExpandItemsPerStep = 3;

@interface ViewController () <MLListDataSource, MLManagerDelegate>

@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) IGListAdapter *adapter;
@property (nonatomic, strong) MLListManager *listManager;
@property (nonatomic, strong) NSArray<id<MLListItemProtocol>> *items;

- (MLDemoListItem *)nodeWithId:(NSString *)nodeId name:(NSString *)name children:(NSArray<MLDemoListItem *> *)children;
- (MLDemoListItem *)groupNodeWithId:(NSString *)nodeId name:(NSString *)name leafTitles:(NSArray<NSString *> *)leafTitles;
- (NSArray<MLDemoListItem *> *)leafNodesWithPrefix:(NSString *)prefix titles:(NSArray<NSString *> *)titles;
- (void)expandNode:(MLDemoListItem *)node initialVisibleCount:(NSInteger)count;
- (void)handleTitleCellLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)presentDeleteConfirmationForModel:(MLFlattenedItemModel *)model;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    [self buildUI];
    [self buildListManager];
    [self buildSampleData];
    [self.listManager performUpdatesAnimated:NO completion:nil];
}

#pragma mark - Build UI

- (void)buildUI {
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.tipLabel.numberOfLines = 0;
    self.tipLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    self.tipLabel.textColor = UIColor.secondaryLabelColor;
    self.tipLabel.text = @"MLListManager 示例：点击节点触发业务事件，点击 footer 分批展开或收起子节点。";
    [self.view addSubview:self.tipLabel];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0.0;
    layout.minimumInteritemSpacing = 0.0;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    [self.view addSubview:self.collectionView];
    
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tipLabel.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:16.0],
        [self.tipLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.tipLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        
        [self.collectionView.topAnchor constraintEqualToAnchor:self.tipLabel.bottomAnchor constant:12.0],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)buildListManager {
    IGListAdapterUpdater *updater = [[IGListAdapterUpdater alloc] init];
    self.adapter = [[IGListAdapter alloc] initWithUpdater:updater viewController:self];
    self.adapter.collectionView = self.collectionView;
    
    self.listManager = [[MLListManager alloc] initWithAdapter:self.adapter];
    self.listManager.dataSource = self;
    self.listManager.delegate = self;
    self.tipLabel.text = [NSString stringWithFormat:@"MLListManager 示例：当前 footer 每次展开 %ld 项，支持继续展开和收起。", (long)kDemoExpandItemsPerStep];
}

#pragma mark - Sample Data

- (void)buildSampleData {         
    MLDemoListItem *organizationExample = [self nodeWithId:@"example-organization"
                                                      name:@"组织架构示例"
                                                  children:@[
        [self nodeWithId:@"example-organization-ios"
                    name:@"iOS 平台组"
                children:@[
            [self groupNodeWithId:@"example-organization-ios-ui"
                             name:@"页面体验方向"
                       leafTitles:@[@"首页改版", @"评论楼层", @"直播动效", @"会场搭建", @"夜间主题"]],
            [self groupNodeWithId:@"example-organization-ios-base"
                             name:@"基础架构方向"
                       leafTitles:@[@"Router 重构", @"A/B 组件", @"监控上报", @"崩溃治理", @"启动优化"]]
        ]],
        [self nodeWithId:@"example-organization-android"
                    name:@"Android 平台组"
                children:@[
            [self groupNodeWithId:@"example-organization-android-performance"
                             name:@"性能治理方向"
                       leafTitles:@[@"冷启动治理", @"包体瘦身", @"卡顿追踪", @"渲染优化"]],
            [self groupNodeWithId:@"example-organization-android-commerce"
                             name:@"商店能力方向"
                       leafTitles:@[@"商品详情", @"购物车联动", @"订单确认", @"优惠券中心"]]
        ]],
        [self nodeWithId:@"example-organization-cross"
                    name:@"跨端工程组"
                children:@[
            [self groupNodeWithId:@"example-organization-cross-rn"
                             name:@"RN 工程化"
                       leafTitles:@[@"容器升级", @"热更新接入", @"通用桥封装", @"埋点对齐"]],
            [self groupNodeWithId:@"example-organization-cross-miniapp"
                             name:@"MiniApp 容器"
                       leafTitles:@[@"预加载策略", @"离线包管理", @"权限模型", @"页面骨架"]]
        ]],
        [self nodeWithId:@"example-organization-video"
                    name:@"音视频互动组"
                children:@[
            [self groupNodeWithId:@"example-organization-video-room"
                             name:@"连麦房间"
                       leafTitles:@[@"房间状态机", @"礼物面板", @"麦位控制", @"场控工具"]],
            [self groupNodeWithId:@"example-organization-video-player"
                             name:@"播放器内核"
                       leafTitles:@[@"首帧优化", @"清晰度切换", @"弱网恢复", @"边播边下"]]
        ]],
        [self nodeWithId:@"example-organization-growth"
                    name:@"商业化增长组"
                children:@[
            [self groupNodeWithId:@"example-organization-growth-funnel"
                             name:@"转化漏斗"
                       leafTitles:@[@"新客承接", @"留存召回", @"权益弹层", @"Push 触达"]],
            [self groupNodeWithId:@"example-organization-growth-ads"
                             name:@"广告变现"
                       leafTitles:@[@"开屏投放", @"信息流广告", @"奖励激励", @"回传打点"]]
        ]],
        [self nodeWithId:@"example-organization-quality"
                    name:@"体验保障组"
                children:@[
            [self groupNodeWithId:@"example-organization-quality-auto"
                             name:@"自动化测试"
                       leafTitles:@[@"冒烟用例", @"回归流水线", @"截图对比", @"告警订阅"]],
            [self groupNodeWithId:@"example-organization-quality-inspection"
                             name:@"线上巡检"
                       leafTitles:@[@"核心链路巡检", @"发布看板", @"灰度守护", @"异常回滚"]]
        ]]
    ]];
    
    MLDemoListItem *commentExample = [self nodeWithId:@"example-comment"
                                                 name:@"评论楼中楼示例"
                                             children:@[
        [self nodeWithId:@"example-comment-1"
                    name:@"主贴 1：这版展开样式已经更像评论区了"
                children:@[
            [self groupNodeWithId:@"example-comment-1-reply-1"
                             name:@"回复 1-1：footer 放在子节点最后体验更自然"
                       leafTitles:@[@"继续回复：尤其是连续展开时不会跳", @"继续回复：层级视觉也更顺", @"继续回复：适合长评论场景"]],
            [self groupNodeWithId:@"example-comment-1-reply-2"
                             name:@"回复 1-2：如果一次只多展开 3 条就更真实"
                       leafTitles:@[@"继续回复：避免一下子刷太长", @"继续回复：适合接口分页", @"继续回复：文案也要提示数量"]]
        ]],
        [self nodeWithId:@"example-comment-2"
                    name:@"主贴 2：业务方自己配置 cell 会更灵活"
                children:@[
            [self groupNodeWithId:@"example-comment-2-reply-1"
                             name:@"回复 2-1：manager 只管结构更清晰"
                       leafTitles:@[@"继续回复：绑定交给业务更合理", @"继续回复：自定义埋点也方便", @"继续回复：样式不会被框架锁死"]],
            [self groupNodeWithId:@"example-comment-2-reply-2"
                             name:@"回复 2-2：section inset 也应该代理出去"
                       leafTitles:@[@"继续回复：不同业务缩进规则不一样", @"继续回复：还能做品牌化布局"]]
        ]],
        [self nodeWithId:@"example-comment-3"
                    name:@"主贴 3：如果节点很多，展开最好按批次来"
                children:@[
            [self groupNodeWithId:@"example-comment-3-reply-1"
                             name:@"回复 3-1：先看三条，再决定要不要继续"
                       leafTitles:@[@"继续回复：非常接近主流评论产品", @"继续回复：不会打断阅读节奏"]],
            [self groupNodeWithId:@"example-comment-3-reply-2"
                             name:@"回复 3-2：最后一批露完后再切成收起"
                       leafTitles:@[@"继续回复：状态更明确", @"继续回复：用户心智也稳定"]]
        ]],
        [self groupNodeWithId:@"example-comment-4"
                         name:@"主贴 4：loading 放在 footer 很合适"
                   leafTitles:@[@"回复 4-1：不会影响正文阅读", @"回复 4-2：操作反馈也及时", @"回复 4-3：弱网场景更友好"]],
        [self groupNodeWithId:@"example-comment-5"
                         name:@"主贴 5：多场景例子很有帮助"
                   leafTitles:@[@"回复 5-1：接入时更好参考", @"回复 5-2：也方便验证 diff 刷新", @"回复 5-3：更能看出层级关系"]],
        [self groupNodeWithId:@"example-comment-6"
                         name:@"主贴 6：现在这套已经很接近业务组件了"
                   leafTitles:@[@"回复 6-1：只差真实接口数据", @"回复 6-2：真机表现也要确认", @"回复 6-3：最好再补日志和埋点"]]
    ]];
    
    MLDemoListItem *projectExample = [self nodeWithId:@"example-project"
                                                 name:@"项目拆解示例"
                                             children:@[
        [self groupNodeWithId:@"example-project-discovery"
                         name:@"阶段 1：需求澄清"
                   leafTitles:@[@"业务目标", @"场景拆分", @"数据口径", @"风险清单", @"验收标准"]],
        [self groupNodeWithId:@"example-project-design"
                         name:@"阶段 2：方案设计"
                   leafTitles:@[@"交互稿评审", @"接口协议", @"埋点规划", @"兼容性矩阵", @"灰度方案"]],
        [self groupNodeWithId:@"example-project-dev"
                         name:@"阶段 3：开发联调"
                   leafTitles:@[@"iOS 开发", @"Android 开发", @"服务端联调", @"测试桩数据", @"回归修复"]],
        [self groupNodeWithId:@"example-project-release"
                         name:@"阶段 4：发布上线"
                   leafTitles:@[@"灰度开关", @"线上巡检", @"兜底预案", @"客服同步", @"看板观察"]],
        [self groupNodeWithId:@"example-project-review"
                         name:@"阶段 5：效果复盘"
                   leafTitles:@[@"数据复盘", @"问题回收", @"ROI 评估", @"二期规划", @"经验沉淀"]],
        [self groupNodeWithId:@"example-project-collaboration"
                         name:@"阶段 6：跨团队协作"
                   leafTitles:@[@"产品同步", @"设计走查", @"测试排期", @"运营培训", @"法务确认"]]
    ]];
    
    MLDemoListItem *knowledgeExample = [self nodeWithId:@"example-knowledge"
                                                   name:@"知识目录示例"
                                               children:@[
        [self groupNodeWithId:@"example-knowledge-objc"
                         name:@"章节 1：Objective-C 基础"
                   leafTitles:@[@"对象模型", @"属性语义", @"分类与扩展", @"Block", @"Runtime"]],
        [self groupNodeWithId:@"example-knowledge-uikit"
                         name:@"章节 2：UIKit 列表体系"
                   leafTitles:@[@"UITableView", @"UICollectionView", @"Diff 刷新", @"复用机制", @"交互反馈"]],
        [self groupNodeWithId:@"example-knowledge-iglistkit"
                         name:@"章节 3：IGListKit 实战"
                   leafTitles:@[@"Adapter", @"SectionController", @"Diffable", @"Working Range", @"性能优化"]],
        [self groupNodeWithId:@"example-knowledge-architecture"
                         name:@"章节 4：组件化设计"
                   leafTitles:@[@"协议抽象", @"状态收口", @"业务代理", @"可扩展 API", @"回归验证"]],
        [self groupNodeWithId:@"example-knowledge-quality"
                         name:@"章节 5：质量保障"
                   leafTitles:@[@"内存泄漏", @"线程安全", @"埋点校验", @"真机构建", @"异常兜底"]]
    ]];
    
    MLDemoListItem *commerceExample = [self nodeWithId:@"example-commerce"
                                                  name:@"商品分类示例"
                                              children:@[
        [self groupNodeWithId:@"example-commerce-digital"
                         name:@"分类 1：数码产品"
                   leafTitles:@[@"手机", @"平板", @"耳机", @"手表", @"路由器"]],
        [self groupNodeWithId:@"example-commerce-household"
                         name:@"分类 2：家用电器"
                   leafTitles:@[@"冰箱", @"洗衣机", @"投影仪", @"空气净化器", @"扫地机器人"]],
        [self groupNodeWithId:@"example-commerce-beauty"
                         name:@"分类 3：美妆护肤"
                   leafTitles:@[@"精华", @"面膜", @"防晒", @"底妆", @"香氛"]],
        [self groupNodeWithId:@"example-commerce-food"
                         name:@"分类 4：食品生鲜"
                   leafTitles:@[@"水果", @"乳品", @"速食", @"坚果", @"咖啡"]],
        [self groupNodeWithId:@"example-commerce-sport"
                         name:@"分类 5：运动户外"
                   leafTitles:@[@"跑鞋", @"瑜伽垫", @"骑行装备", @"露营帐篷", @"运动手环"]],
        [self groupNodeWithId:@"example-commerce-pet"
                         name:@"分类 6：宠物生活"
                   leafTitles:@[@"主粮", @"零食", @"玩具", @"出行箱", @"清洁用品"]]
    ]];
    
    [self expandNode:organizationExample initialVisibleCount:kDemoExpandItemsPerStep];
    [self expandNode:(MLDemoListItem *)organizationExample.children.firstObject initialVisibleCount:kDemoExpandItemsPerStep];
    [self expandNode:commentExample initialVisibleCount:kDemoExpandItemsPerStep];
    [self expandNode:projectExample initialVisibleCount:2];
    
    self.items = @[organizationExample, commentExample, projectExample, knowledgeExample, commerceExample];
}

- (MLDemoListItem *)nodeWithId:(NSString *)nodeId name:(NSString *)name children:(NSArray<MLDemoListItem *> *)children {
    MLDemoListItem *node = [[MLDemoListItem alloc] initWithItemId:nodeId title:name totalChildrenCount:children.count];
    [node.children addObjectsFromArray:children];
    return node;
}

- (MLDemoListItem *)groupNodeWithId:(NSString *)nodeId name:(NSString *)name leafTitles:(NSArray<NSString *> *)leafTitles {
    return [self nodeWithId:nodeId
                       name:name
                   children:[self leafNodesWithPrefix:nodeId titles:leafTitles]];
}

- (NSArray<MLDemoListItem *> *)leafNodesWithPrefix:(NSString *)prefix titles:(NSArray<NSString *> *)titles {
    NSMutableArray<MLDemoListItem *> *leafNodes = [NSMutableArray arrayWithCapacity:titles.count];
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        NSString *nodeId = [NSString stringWithFormat:@"%@-leaf-%lu", prefix, (unsigned long)idx];
        [leafNodes addObject:[self nodeWithId:nodeId name:title children:@[]]];
    }];
    return [leafNodes copy];
}

- (void)expandNode:(MLDemoListItem *)node initialVisibleCount:(NSInteger)count {
    NSInteger visibleCount = MIN(MAX(count, 0), node.children.count);
    node.visibleChildrenCount = visibleCount;
}

#pragma mark - MLListDataSource

- (UIView *)emptyViewForMLListManager:(MLListManager *)listManager {
    if (self.items.count > 0) {
        return nil;
    }
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"暂无数据";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.secondaryLabelColor;
    return label;
}

- (NSArray<id<MLListItemProtocol>> *)objectsForMLListManager:(MLListManager *)listManager {
    return self.items;
}

#pragma mark - MLManagerDelegate

- (UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController cellForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    MLDemoTitleCell *cell = [sectionController.collectionContext dequeueReusableCellOfClass:MLDemoTitleCell.class forSectionController:sectionController atIndex:index];
    [cell configureWithModel:model];
    BOOL hasLongPress = NO;
    for (UIGestureRecognizer *gestureRecognizer in cell.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:UILongPressGestureRecognizer.class]) {
            hasLongPress = YES;
            break;
        }
    }
    if (!hasLongPress) {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTitleCellLongPress:)];
        [cell addGestureRecognizer:longPressGesture];
    }
    return cell;
}

- (UICollectionViewCell *)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController footerForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    MLDemoFooterCell *cell = [sectionController.collectionContext dequeueReusableCellOfClass:MLDemoFooterCell.class forSectionController:sectionController atIndex:index];
    [cell configureWithModel:model];
    return cell;
}

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController cellSizeForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    UIEdgeInsets sectionInset = [self flattenedItemSectionController:sectionController insetForItemModel:model];
    CGFloat width = sectionController.collectionContext.containerSize.width - sectionInset.left - sectionInset.right;
    return CGSizeMake(MAX(width, 0.0), 52.0);
}

- (CGSize)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController footerSizeForItemAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    UIEdgeInsets sectionInset = [self flattenedItemSectionController:sectionController insetForItemModel:model];
    CGFloat width = sectionController.collectionContext.containerSize.width - sectionInset.left - sectionInset.right;
    return CGSizeMake(MAX(width, 0.0), 30.0);
}

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController didSelectCellAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    MLDemoListItem *item = (MLDemoListItem *)model.differableObject;
    self.tipLabel.text = [NSString stringWithFormat:@"点击节点：%@，当前层级：%ld。", item.title, (long)model.level + 1];
    
    if (!self.listManager.flattenService.params.usesFooter && model.totalChildrenCount > 0) {
        if (model.status == MLFlattenedItemStatusCollapsed || model.status == MLFlattenedItemStatusPartiallyExpanded) {
            [self.listManager appendFlattenItemsWithModel:model animated:YES completion:nil];
        } else if (model.status == MLFlattenedItemStatusFullyExpanded) {
            [self.listManager collapseFlattenItemsWithModel:model animated:YES completion:nil];
        }
    }
}

- (void)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController didSelectFooterAtIndex:(NSInteger)index withItemModel:(MLFlattenedItemModel *)model {
    if (model.status == MLFlattenedItemStatusLoading || model.status == MLFlattenedItemStatusCollapsing) {
        return;
    }
    
    if (model.status == MLFlattenedItemStatusCollapsed || model.status == MLFlattenedItemStatusPartiallyExpanded) {
        model.status = MLFlattenedItemStatusLoading;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.listManager appendFlattenItemsWithModel:model animated:YES completion:nil];
        });
        return;
    } else if (model.status == MLFlattenedItemStatusFullyExpanded) {
        model.status = MLFlattenedItemStatusCollapsing;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.listManager collapseFlattenItemsWithModel:model animated:YES completion:nil];
        });
    }
}

- (UIEdgeInsets)flattenedItemSectionController:(MLFlattenedItemSectionController *)sectionController insetForItemModel:(MLFlattenedItemModel *)model {
    CGFloat leftInset = model.level * 20.0;
    return UIEdgeInsetsMake(2.0, leftInset, 2.0, 0.0);
}

#pragma mark - Delete Example

- (void)handleTitleCellLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    MLDemoTitleCell *cell = (MLDemoTitleCell *)gestureRecognizer.view;
    if (![cell isKindOfClass:MLDemoTitleCell.class] || cell.model == nil) {
        return;
    }
    
    [self presentDeleteConfirmationForModel:cell.model];
}

- (void)presentDeleteConfirmationForModel:(MLFlattenedItemModel *)model {
    MLDemoListItem *item = (MLDemoListItem *)model.differableObject;
    NSString *message = [NSString stringWithFormat:@"确定删除「%@」吗？", item.title];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"删除节点"
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [self.listManager deleteFlattenItemsWithModel:model animated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
