#import <XCTest/XCTest.h>

#import "Internal/MLFlattenedItemModelInternal.h"
#import "MLListFlattenService.h"

@interface MLTestItem : NSObject <MLListItemProtocol>

@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, nullable, strong) NSMutableArray<id<MLListItemProtocol>> *children;
@property (nonatomic, assign) NSInteger totalChildrenCount;
@property (nonatomic, assign) NSInteger initialVisibleChildrenCount;

@end

@implementation MLTestItem

- (instancetype)initWithItemId:(NSString *)itemId children:(NSArray<MLTestItem *> *)children {
    if (self = [super init]) {
        _itemId = [itemId copy];
        _children = [children mutableCopy];
        _totalChildrenCount = children.count;
        _initialVisibleChildrenCount = 0;
    }
    return self;
}

- (id<NSObject>)diffIdentifier {
    return self.itemId;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object {
    if (self == object) {
        return YES;
    }
    if (![(id)object isKindOfClass:MLTestItem.class]) {
        return NO;
    }

    MLTestItem *item = (MLTestItem *)object;
    return [self.itemId isEqualToString:item.itemId]
        && self.children.count == item.children.count
        && self.totalChildrenCount == item.totalChildrenCount
        && self.initialVisibleChildrenCount == item.initialVisibleChildrenCount;
}

@end

@interface MLListFlattenServiceTests : XCTestCase

@end

@implementation MLListFlattenServiceTests

- (MLTestItem *)itemWithId:(NSString *)itemId {
    return [[MLTestItem alloc] initWithItemId:itemId children:@[]];
}

- (MLTestItem *)itemWithId:(NSString *)itemId children:(NSArray<MLTestItem *> *)children visibleCount:(NSInteger)visibleCount {
    MLTestItem *item = [[MLTestItem alloc] initWithItemId:itemId children:children];
    item.initialVisibleChildrenCount = visibleCount;
    return item;
}

- (MLListFlattenService *)serviceWithRootItems:(NSArray<MLTestItem *> *)rootItems {
    return [self serviceWithRootItems:rootItems usesFooter:YES];
}

- (MLListFlattenService *)serviceWithRootItems:(NSArray<MLTestItem *> *)rootItems usesFooter:(BOOL)usesFooter {
    return [self serviceWithRootItems:rootItems usesFooter:usesFooter collapsesDescendantsOnCollapse:NO];
}

- (MLListFlattenService *)serviceWithRootItems:(NSArray<MLTestItem *> *)rootItems
                                    usesFooter:(BOOL)usesFooter
                collapsesDescendantsOnCollapse:(BOOL)collapsesDescendantsOnCollapse {
    MLListFlattenParams *params = [[MLListFlattenParams alloc] init];
    params.usesFooter = usesFooter;
    params.expandBatchCount = 2;
    params.collapsesDescendantsOnCollapse = collapsesDescendantsOnCollapse;
    params.defaultVisibleChildrenCountProvider = ^NSInteger(id<MLListItemProtocol> item,
                                                            __unused NSInteger level,
                                                            __unused id<MLListItemProtocol> parentItem) {
        return ((MLTestItem *)item).initialVisibleChildrenCount;
    };
    MLListFlattenService *service = [[MLListFlattenService alloc] initWithParams:params];
    service.rootItems = [rootItems mutableCopy];
    return service;
}

- (MLFlattenedItemModel *)modelInService:(MLListFlattenService *)service
                                    item:(id<MLListItemProtocol>)item
                                    type:(MLFlattenedItemType)type {
    for (MLFlattenedItemModel *model in service.visibleItems) {
        if (model.differableObject == item && model.type == type) {
            return model;
        }
    }
    return nil;
}

- (NSArray<NSString *> *)visibleIdentifiersInService:(MLListFlattenService *)service {
    NSMutableArray<NSString *> *identifiers = [NSMutableArray arrayWithCapacity:service.visibleItems.count];
    for (MLFlattenedItemModel *model in service.visibleItems) {
        MLTestItem *item = (MLTestItem *)model.differableObject;
        NSString *suffix = model.type == MLFlattenedItemTypeFooter ? @"footer" : @"cell";
        [identifiers addObject:[NSString stringWithFormat:@"%@-%@", item.itemId, suffix]];
    }
    return [identifiers copy];
}

- (void)testInitialFlattenBuildsVisibleChildrenAndFooters {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];

    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-1-cell", @"root-footer"]));
    
    MLFlattenedItemModel *rootModel = [self modelInService:service item:root type:MLFlattenedItemTypeCell];
    MLFlattenedItemModel *footerModel = [self modelInService:service item:root type:MLFlattenedItemTypeFooter];
    XCTAssertEqual(rootModel.itemState.displayStatus, MLListItemDisplayStatusPartiallyExpanded);
    XCTAssertEqual(footerModel.remainingChildrenCount, 1);
}

- (void)testDefaultVisibleChildrenCountProviderSeedsEachNode {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *child3 = [self itemWithId:@"child-3"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2, child3] visibleCount:0];
    MLListFlattenParams *params = [[MLListFlattenParams alloc] init];
    params.defaultVisibleChildrenCountProvider = ^NSInteger(id<MLListItemProtocol> item, NSInteger level, id<MLListItemProtocol> parentItem) {
        MLTestItem *testItem = (MLTestItem *)item;
        return [testItem.itemId isEqualToString:@"root"] && level == 0 && parentItem == nil ? 2 : 0;
    };
    MLListFlattenService *service = [[MLListFlattenService alloc] initWithParams:params];

    service.rootItems = [@[root] mutableCopy];

    XCTAssertEqual(root.initialVisibleChildrenCount, 0);
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 2);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-1-cell", @"child-2-cell", @"root-footer"]));
}

- (void)testAppendVisibleChildrenExpandsByBatchAndRefreshesFooter {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *child3 = [self itemWithId:@"child-3"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2, child3] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    MLFlattenedItemModel *footerModel = [self modelInService:service item:root type:MLFlattenedItemTypeFooter];
    [service appendVisibleChildenItemsForRootModel:footerModel];
    
    XCTAssertEqual(root.initialVisibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-1-cell", @"child-2-cell", @"child-3-cell", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 3);
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeFooter].itemState.displayStatus, MLListItemDisplayStatusFullyExpanded);
}

- (void)testAppendVisibleChildrenWithNilOrFullyExpandedModelDoesNothing {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    NSArray<NSString *> *oldIdentifiers = [self visibleIdentifiersInService:service];
    
    [service appendVisibleChildenItemsForRootModel:nil];
    [service appendVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    
    XCTAssertEqual(root.initialVisibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], oldIdentifiers);
}

- (void)testAppendVisibleChildrenWithoutFooterExpandsAllChildren {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *child3 = [self itemWithId:@"child-3"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2, child3] visibleCount:0];
    MLListFlattenService *service = [self serviceWithRootItems:@[root] usesFooter:NO];
    
    [service appendVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeCell]];
    
    XCTAssertEqual(root.initialVisibleChildrenCount, 0);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-1-cell", @"child-2-cell", @"child-3-cell"]));
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 3);
}

- (void)testCollapseRemovesVisibleChildrenButKeepsFooter {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2] visibleCount:2];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    MLFlattenedItemModel *footerModel = [self modelInService:service item:root type:MLFlattenedItemTypeFooter];
    [service collapseVisibleChildenItemsForRootModel:footerModel];
    
    XCTAssertEqual(root.initialVisibleChildrenCount, 2);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 0);
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeFooter].itemState.displayStatus, MLListItemDisplayStatusCollapsed);
}

- (void)testCollapseKeepsDescendantExpansionWhenDisabled {
    MLTestItem *leaf = [self itemWithId:@"leaf"];
    MLTestItem *child = [self itemWithId:@"child" children:@[leaf] visibleCount:1];
    MLTestItem *root = [self itemWithId:@"root" children:@[child] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    [service collapseVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    [service appendVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    
    XCTAssertEqual(child.initialVisibleChildrenCount, 1);
    XCTAssertEqual([self modelInService:service item:child type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-cell", @"leaf-cell", @"child-footer", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:child type:MLFlattenedItemTypeCell].itemState.displayStatus, MLListItemDisplayStatusFullyExpanded);
}

- (void)testCollapseCanCollapseDescendants {
    MLTestItem *leaf = [self itemWithId:@"leaf"];
    MLTestItem *grandchild = [self itemWithId:@"grandchild" children:@[leaf] visibleCount:1];
    MLTestItem *child = [self itemWithId:@"child" children:@[grandchild] visibleCount:1];
    MLTestItem *root = [self itemWithId:@"root" children:@[child] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]
                                                    usesFooter:YES
                                collapsesDescendantsOnCollapse:YES];
    
    [service collapseVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    [service appendVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    
    XCTAssertEqual(child.initialVisibleChildrenCount, 1);
    XCTAssertEqual(grandchild.initialVisibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-cell", @"child-footer", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:child type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 0);
    XCTAssertEqual([self modelInService:service item:child type:MLFlattenedItemTypeCell].itemState.displayStatus, MLListItemDisplayStatusCollapsed);
}

- (void)testCollapseNilOrCollapsedModelDoesNothing {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1] visibleCount:0];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    NSArray<NSString *> *oldIdentifiers = [self visibleIdentifiersInService:service];
    
    [service collapseVisibleChildenItemsForRootModel:nil];
    [service collapseVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    
    XCTAssertEqual(root.initialVisibleChildrenCount, 0);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], oldIdentifiers);
}

- (void)testInsertRootItemsAtIndexPreservesOrder {
    MLTestItem *root1 = [self itemWithId:@"root-1"];
    MLTestItem *root2 = [self itemWithId:@"root-2"];
    MLTestItem *inserted1 = [self itemWithId:@"inserted-1"];
    MLTestItem *inserted2 = [self itemWithId:@"inserted-2"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root1, root2]];
    
    [service insertRootItems:@[inserted1, inserted2] atIndex:1];
    
    XCTAssertEqualObjects(service.rootItems, (@[root1, inserted1, inserted2, root2]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-1-cell", @"inserted-1-cell", @"inserted-2-cell", @"root-2-cell"]));
}

- (void)testInsertRootItemsAtOutOfBoundsIndexAppends {
    MLTestItem *root = [self itemWithId:@"root"];
    MLTestItem *inserted = [self itemWithId:@"inserted"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    [service insertRootItems:@[inserted] atIndex:100];
    
    XCTAssertEqualObjects(service.rootItems, (@[root, inserted]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"inserted-cell"]));
}

- (void)testInsertRootItemsByPositionFirstAndLast {
    MLTestItem *root = [self itemWithId:@"root"];
    MLTestItem *first = [self itemWithId:@"first"];
    MLTestItem *last = [self itemWithId:@"last"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    [service insertRootItem:first position:MLListInsertPositionFirst];
    [service insertRootItems:@[last] position:MLListInsertPositionLast];
    
    XCTAssertEqualObjects(service.rootItems, (@[first, root, last]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"first-cell", @"root-cell", @"last-cell"]));
}

- (void)testRootMutationsKeepBusinessRootArraySynchronized {
    MLTestItem *root = [self itemWithId:@"root"];
    MLTestItem *inserted = [self itemWithId:@"inserted"];
    NSMutableArray<id<MLListItemProtocol>> *rootItems = [@[root] mutableCopy];
    MLListFlattenService *service = [[MLListFlattenService alloc] initWithParams:nil];
    service.rootItems = rootItems;
    
    [service insertRootItem:inserted position:MLListInsertPositionLast];
    
    XCTAssertEqual(service.rootItems, rootItems);
    XCTAssertEqualObjects(rootItems, (@[root, inserted]));
    
    [service deleteVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeCell]];
    
    XCTAssertEqual(service.rootItems, rootItems);
    XCTAssertEqualObjects(rootItems, (@[inserted]));
}

- (void)testVisibleModelMatchingModelUsesCurrentVisibleIndex {
    MLTestItem *oldRoot = [self itemWithId:@"root"];
    MLListFlattenService *service = [self serviceWithRootItems:@[oldRoot]];
    MLFlattenedItemModel *oldModel = [self modelInService:service item:oldRoot type:MLFlattenedItemTypeCell];
    MLTestItem *newRoot = [self itemWithId:@"root"];

    service.rootItems = [@[newRoot] mutableCopy];

    MLFlattenedItemModel *currentModel = [service visibleModelMatchingModel:oldModel];
    XCTAssertNotNil(currentModel);
    XCTAssertNotEqual(currentModel, oldModel);
    XCTAssertEqual(currentModel.differableObject, newRoot);
}

- (void)testAppendWithStaleModelUsesCurrentVisibleIndex {
    MLTestItem *oldChild = [self itemWithId:@"old-child"];
    MLTestItem *oldRoot = [self itemWithId:@"root" children:@[oldChild] visibleCount:0];
    MLListFlattenService *service = [self serviceWithRootItems:@[oldRoot]];
    MLFlattenedItemModel *oldFooterModel = [self modelInService:service item:oldRoot type:MLFlattenedItemTypeFooter];
    MLTestItem *newChild = [self itemWithId:@"new-child"];
    MLTestItem *newRoot = [self itemWithId:@"root" children:@[newChild] visibleCount:0];

    service.rootItems = [@[newRoot] mutableCopy];
    [service appendVisibleChildenItemsForRootModel:oldFooterModel];

    XCTAssertNil([self modelInService:service item:oldChild type:MLFlattenedItemTypeCell]);
    XCTAssertEqual([self modelInService:service item:newRoot type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"new-child-cell", @"root-footer"]));
}

- (void)testInsertItemsToStaleParentUsesCurrentVisibleIndex {
    MLTestItem *oldRoot = [self itemWithId:@"root"];
    MLListFlattenService *service = [self serviceWithRootItems:@[oldRoot]];
    MLTestItem *newRoot = [self itemWithId:@"root"];
    MLTestItem *inserted = [self itemWithId:@"inserted"];

    service.rootItems = [@[newRoot] mutableCopy];
    [service insertItem:inserted toParentItem:oldRoot position:MLListInsertPositionLast];

    XCTAssertEqual(oldRoot.children.count, 0);
    XCTAssertEqualObjects(newRoot.children, (@[inserted]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"inserted-cell"]));
}

- (void)testInsertEmptyRootItemsDoesNothing {
    MLTestItem *root = [self itemWithId:@"root"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    NSArray<NSString *> *oldIdentifiers = [self visibleIdentifiersInService:service];
    
    [service insertRootItems:@[] atIndex:0];
    
    XCTAssertEqualObjects(service.rootItems, (@[root]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], oldIdentifiers);
}

- (void)testInsertItemsToVisibleParentAtFirstAndLast {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    MLTestItem *first = [self itemWithId:@"first"];
    MLTestItem *last = [self itemWithId:@"last"];
    [service insertItem:first toParentItem:root position:MLListInsertPositionFirst];
    [service insertItem:last toParentItem:root position:MLListInsertPositionLast];
    
    XCTAssertEqualObjects(root.children, (@[first, child1, last, child2]));
    XCTAssertEqual(root.initialVisibleChildrenCount, 1);
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 3);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"first-cell", @"child-1-cell", @"last-cell", @"root-footer"]));
}

- (void)testInsertItemsToParentPreservesBatchOrder {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1] visibleCount:1];
    MLTestItem *inserted1 = [self itemWithId:@"inserted-1"];
    MLTestItem *inserted2 = [self itemWithId:@"inserted-2"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    [service insertItems:@[inserted1, inserted2] toParentItem:root position:MLListInsertPositionLast];
    
    XCTAssertEqualObjects(root.children, (@[child1, inserted1, inserted2]));
    XCTAssertEqual(root.initialVisibleChildrenCount, 1);
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 3);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-1-cell", @"inserted-1-cell", @"inserted-2-cell", @"root-footer"]));
}

- (void)testInsertItemsToInvisibleParentDoesNothing {
    MLTestItem *hiddenParent = [self itemWithId:@"hidden-parent" children:@[] visibleCount:0];
    MLTestItem *root = [self itemWithId:@"root"];
    MLTestItem *inserted = [self itemWithId:@"inserted"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    NSArray<NSString *> *oldIdentifiers = [self visibleIdentifiersInService:service];
    
    [service insertItems:@[inserted] toParentItem:hiddenParent position:MLListInsertPositionLast];
    
    XCTAssertEqual(hiddenParent.children.count, 0);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], oldIdentifiers);
}

- (void)testInsertEmptyItemsToParentDoesNothing {
    MLTestItem *root = [self itemWithId:@"root"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    NSArray<NSString *> *oldIdentifiers = [self visibleIdentifiersInService:service];
    
    [service insertItems:@[] toParentItem:root position:MLListInsertPositionLast];
    
    XCTAssertEqual(root.children.count, 0);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], oldIdentifiers);
}

- (void)testInsertItemsWithNilParentFallsBackToRootInsertion {
    MLTestItem *root = [self itemWithId:@"root"];
    MLTestItem *inserted1 = [self itemWithId:@"inserted-1"];
    MLTestItem *inserted2 = [self itemWithId:@"inserted-2"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    [service insertItems:@[inserted1, inserted2] toParentItem:nil position:MLListInsertPositionLast];
    
    XCTAssertEqualObjects(service.rootItems, (@[root, inserted1, inserted2]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"inserted-1-cell", @"inserted-2-cell"]));
}

- (void)testDeleteRootItemUpdatesRootItemsAndVisibleItems {
    MLTestItem *root1 = [self itemWithId:@"root-1"];
    MLTestItem *root2 = [self itemWithId:@"root-2"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root1, root2]];
    
    [service deleteVisibleChildenItemsForRootModel:[self modelInService:service item:root1 type:MLFlattenedItemTypeCell]];
    
    XCTAssertEqualObjects(service.rootItems, (@[root2]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], (@[@"root-2-cell"]));
}

- (void)testDeleteChildUpdatesParentCountsAndFooter {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2] visibleCount:2];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    MLFlattenedItemModel *childModel = [self modelInService:service item:child1 type:MLFlattenedItemTypeCell];
    [service deleteVisibleChildenItemsForRootModel:childModel];
    
    XCTAssertEqualObjects(root.children, (@[child2]));
    XCTAssertEqual(root.totalChildrenCount, 1);
    XCTAssertEqual(root.initialVisibleChildrenCount, 2);
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.visibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-2-cell", @"root-footer"]));
}

- (void)testDeleteLastChildRemovesParentFooter {
    MLTestItem *child = [self itemWithId:@"child"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    [service deleteVisibleChildenItemsForRootModel:[self modelInService:service item:child type:MLFlattenedItemTypeCell]];
    
    XCTAssertEqual(root.children.count, 0);
    XCTAssertEqual(root.totalChildrenCount, 0);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], (@[@"root-cell"]));
}

- (void)testDeleteNilOrInvisibleModelDoesNothing {
    MLTestItem *root = [self itemWithId:@"root"];
    MLTestItem *outside = [self itemWithId:@"outside"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    MLFlattenedItemModel *outsideModel = [[MLFlattenedItemModel alloc] initWithDifferableObject:outside
                                                                                        parent:nil
                                                                                         level:0
                                                                                          type:MLFlattenedItemTypeCell];
    
    [service deleteVisibleChildenItemsForRootModel:nil];
    [service deleteVisibleChildenItemsForRootModel:outsideModel];
    
    XCTAssertEqualObjects(service.rootItems, (@[root]));
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], (@[@"root-cell"]));
}

- (void)testSetRootItemsRebuildsVisibleItems {
    MLTestItem *oldRoot = [self itemWithId:@"old-root"];
    MLTestItem *newChild = [self itemWithId:@"new-child"];
    MLTestItem *newRoot = [self itemWithId:@"new-root" children:@[newChild] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[oldRoot]];
    
    service.rootItems = [@[newRoot] mutableCopy];
    
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"new-root-cell", @"new-child-cell", @"new-root-footer"]));
}

- (void)testUsesFooterFalseOmitsFooters {
    MLTestItem *child = [self itemWithId:@"child"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root] usesFooter:NO];
    
    XCTAssertNil([self modelInService:service item:root type:MLFlattenedItemTypeFooter]);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], (@[@"root-cell", @"child-cell"]));
}

- (void)testFlattenParamsCopyPreservesValuesAndSeparatesInstances {
    MLListFlattenParams *params = [[MLListFlattenParams alloc] init];
    params.expandBatchCount = 12;
    params.defaultVisibleChildrenCount = 4;
    params.defaultVisibleChildrenCountProvider = ^NSInteger(__unused id<MLListItemProtocol> item,
                                                            __unused NSInteger level,
                                                            __unused id<MLListItemProtocol> parentItem) {
        return 7;
    };
    params.usesFooter = NO;
    params.collapsesDescendantsOnCollapse = YES;
    
    MLListFlattenParams *paramsCopy = [params copy];
    params.expandBatchCount = 1;
    params.defaultVisibleChildrenCount = 0;
    params.defaultVisibleChildrenCountProvider = nil;
    params.usesFooter = YES;
    params.collapsesDescendantsOnCollapse = NO;
    
    XCTAssertNotEqual(paramsCopy, params);
    XCTAssertEqual(paramsCopy.expandBatchCount, 12);
    XCTAssertEqual(paramsCopy.defaultVisibleChildrenCount, 4);
    XCTAssertEqual(paramsCopy.defaultVisibleChildrenCountProvider([self itemWithId:@"root"], 0, nil), 7);
    XCTAssertFalse(paramsCopy.usesFooter);
    XCTAssertTrue(paramsCopy.collapsesDescendantsOnCollapse);
}

- (void)testServiceCopiesInjectedFlattenParams {
    MLListFlattenParams *params = [[MLListFlattenParams alloc] init];
    params.expandBatchCount = 3;
    params.defaultVisibleChildrenCount = 2;
    params.usesFooter = NO;
    params.collapsesDescendantsOnCollapse = YES;
    
    MLListFlattenService *service = [[MLListFlattenService alloc] initWithParams:params];
    params.expandBatchCount = 8;
    params.defaultVisibleChildrenCount = 0;
    params.usesFooter = YES;
    params.collapsesDescendantsOnCollapse = NO;
    
    XCTAssertNotEqual(service.params, params);
    XCTAssertEqual(service.params.expandBatchCount, 3);
    XCTAssertEqual(service.params.defaultVisibleChildrenCount, 2);
    XCTAssertFalse(service.params.usesFooter);
    XCTAssertTrue(service.params.collapsesDescendantsOnCollapse);
}

- (void)testDisplayStatusDidChangeHandlerIsAppliedToExistingAndNewModels {
    MLTestItem *root = [self itemWithId:@"root"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    __block NSInteger callCount = 0;
    service.displayStatusDidChangeHandler = ^(__unused MLFlattenedItemModel *changedModel) {
        callCount++;
    };
    
    [self modelInService:service item:root type:MLFlattenedItemTypeCell].itemState.displayStatus = MLListItemDisplayStatusLoading;
    MLTestItem *inserted = [self itemWithId:@"inserted"];
    [service insertRootItem:inserted position:MLListInsertPositionLast];
    [self modelInService:service item:inserted type:MLFlattenedItemTypeCell].itemState.displayStatus = MLListItemDisplayStatusLoading;
    
    XCTAssertEqual(callCount, 2);
}

- (void)testDisplayStatusChangeDoesNotPersistAcrossRebuild {
    MLTestItem *child = [self itemWithId:@"child"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child] visibleCount:0];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    MLFlattenedItemModel *model = [self modelInService:service item:root type:MLFlattenedItemTypeCell];

    model.itemState.displayStatus = MLListItemDisplayStatusLoading;
    service.rootItems = [@[root] mutableCopy];

    MLFlattenedItemModel *rebuiltModel = [self modelInService:service item:root type:MLFlattenedItemTypeCell];
    XCTAssertEqual(rebuiltModel.itemState.visibleChildrenCount, 0);
    XCTAssertEqual(rebuiltModel.itemState.displayStatus, MLListItemDisplayStatusCollapsed);
}

- (void)testDisplayStatusChangeHandlerFiresOnlyWhenDisplayStatusChanges {
    MLTestItem *root = [self itemWithId:@"root"];
    MLFlattenedItemModel *model = [[MLFlattenedItemModel alloc] initWithDifferableObject:root
                                                                                  parent:nil
                                                                                   level:0
                                                                                    type:MLFlattenedItemTypeCell];
    __block NSInteger callCount = 0;
    model.displayStatusDidChangeHandler = ^(__unused MLFlattenedItemModel *changedModel) {
        callCount++;
    };
    
    model.itemState.displayStatus = MLListItemDisplayStatusLoading;
    model.itemState.displayStatus = MLListItemDisplayStatusLoading;
    model.itemState.displayStatus = MLListItemDisplayStatusLoadFailed;
    
    XCTAssertEqual(callCount, 2);
}

- (void)testDiffEqualityIncludesCountSnapshots {
    MLTestItem *root = [self itemWithId:@"root"];
    root.totalChildrenCount = 3;
    MLFlattenedItemModel *oldModel = [[MLFlattenedItemModel alloc] initWithDifferableObject:root
                                                                                    parent:nil
                                                                                     level:0
                                                                                      type:MLFlattenedItemTypeFooter
                                                                      visibleChildrenCount:1];
    
    MLFlattenedItemModel *newModel = [[MLFlattenedItemModel alloc] initWithDifferableObject:root
                                                                                    parent:nil
                                                                                     level:0
                                                                                      type:MLFlattenedItemTypeFooter
                                                                      visibleChildrenCount:2];
    
    XCTAssertFalse([oldModel isEqualToDiffableObject:newModel]);
}

@end
