#import <XCTest/XCTest.h>

#import "Internal/MLFlattenedItemModelInternal.h"
#import "MLListFlattenService.h"

@interface MLTestItem : NSObject <MLListItemProtocol>

@property (nonatomic, copy) NSString *itemId;
@property (nonatomic, nullable, strong) NSMutableArray<id<MLListItemProtocol>> *children;
@property (nonatomic, assign) NSInteger totalChildrenCount;
@property (nonatomic, assign) NSInteger visibleChildrenCount;

@end

@implementation MLTestItem

- (instancetype)initWithItemId:(NSString *)itemId children:(NSArray<MLTestItem *> *)children {
    if (self = [super init]) {
        _itemId = [itemId copy];
        _children = [children mutableCopy];
        _totalChildrenCount = children.count;
        _visibleChildrenCount = 0;
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
        && self.visibleChildrenCount == item.visibleChildrenCount;
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
    item.visibleChildrenCount = visibleCount;
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
    MLListFlattenService *service = [[MLListFlattenService alloc] initWithParams:params];
    service.rootItems = rootItems;
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
    XCTAssertEqual(rootModel.status, MLFlattenedItemStatusPartiallyExpanded);
    XCTAssertEqual(footerModel.remainingChildrenCount, 1);
}

- (void)testAppendVisibleChildrenExpandsByBatchAndRefreshesFooter {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *child3 = [self itemWithId:@"child-3"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2, child3] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    MLFlattenedItemModel *footerModel = [self modelInService:service item:root type:MLFlattenedItemTypeFooter];
    [service appendVisibleChildenItemsForRootModel:footerModel];
    
    XCTAssertEqual(root.visibleChildrenCount, 3);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-1-cell", @"child-2-cell", @"child-3-cell", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeFooter].status, MLFlattenedItemStatusFullyExpanded);
}

- (void)testAppendVisibleChildrenWithNilOrFullyExpandedModelDoesNothing {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    NSArray<NSString *> *oldIdentifiers = [self visibleIdentifiersInService:service];
    
    [service appendVisibleChildenItemsForRootModel:nil];
    [service appendVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    
    XCTAssertEqual(root.visibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service], oldIdentifiers);
}

- (void)testAppendVisibleChildrenWithoutFooterExpandsAllChildren {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *child3 = [self itemWithId:@"child-3"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2, child3] visibleCount:0];
    MLListFlattenService *service = [self serviceWithRootItems:@[root] usesFooter:NO];
    
    [service appendVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeCell]];
    
    XCTAssertEqual(root.visibleChildrenCount, 3);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-1-cell", @"child-2-cell", @"child-3-cell"]));
}

- (void)testCollapseRemovesVisibleChildrenButKeepsFooter {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *child2 = [self itemWithId:@"child-2"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1, child2] visibleCount:2];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    MLFlattenedItemModel *footerModel = [self modelInService:service item:root type:MLFlattenedItemTypeFooter];
    [service collapseVisibleChildenItemsForRootModel:footerModel];
    
    XCTAssertEqual(root.visibleChildrenCount, 0);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:root type:MLFlattenedItemTypeFooter].status, MLFlattenedItemStatusCollapsed);
}

- (void)testCollapseKeepsDescendantExpansionWhenDisabled {
    MLTestItem *leaf = [self itemWithId:@"leaf"];
    MLTestItem *child = [self itemWithId:@"child" children:@[leaf] visibleCount:1];
    MLTestItem *root = [self itemWithId:@"root" children:@[child] visibleCount:1];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    
    [service collapseVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    [service appendVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    
    XCTAssertEqual(child.visibleChildrenCount, 1);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-cell", @"leaf-cell", @"child-footer", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:child type:MLFlattenedItemTypeCell].status, MLFlattenedItemStatusFullyExpanded);
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
    
    XCTAssertEqual(child.visibleChildrenCount, 0);
    XCTAssertEqual(grandchild.visibleChildrenCount, 0);
    XCTAssertEqualObjects([self visibleIdentifiersInService:service],
                          (@[@"root-cell", @"child-cell", @"child-footer", @"root-footer"]));
    XCTAssertEqual([self modelInService:service item:child type:MLFlattenedItemTypeCell].status, MLFlattenedItemStatusCollapsed);
}

- (void)testCollapseNilOrCollapsedModelDoesNothing {
    MLTestItem *child1 = [self itemWithId:@"child-1"];
    MLTestItem *root = [self itemWithId:@"root" children:@[child1] visibleCount:0];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    NSArray<NSString *> *oldIdentifiers = [self visibleIdentifiersInService:service];
    
    [service collapseVisibleChildenItemsForRootModel:nil];
    [service collapseVisibleChildenItemsForRootModel:[self modelInService:service item:root type:MLFlattenedItemTypeFooter]];
    
    XCTAssertEqual(root.visibleChildrenCount, 0);
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
    XCTAssertEqual(root.visibleChildrenCount, 3);
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
    XCTAssertEqual(root.visibleChildrenCount, 3);
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
    XCTAssertEqual(root.visibleChildrenCount, 1);
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
    
    service.rootItems = @[newRoot];
    
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
    params.usesFooter = NO;
    params.collapsesDescendantsOnCollapse = YES;
    
    MLListFlattenParams *paramsCopy = [params copy];
    params.expandBatchCount = 1;
    params.usesFooter = YES;
    params.collapsesDescendantsOnCollapse = NO;
    
    XCTAssertNotEqual(paramsCopy, params);
    XCTAssertEqual(paramsCopy.expandBatchCount, 12);
    XCTAssertFalse(paramsCopy.usesFooter);
    XCTAssertTrue(paramsCopy.collapsesDescendantsOnCollapse);
}

- (void)testServiceCopiesInjectedFlattenParams {
    MLListFlattenParams *params = [[MLListFlattenParams alloc] init];
    params.expandBatchCount = 3;
    params.usesFooter = NO;
    params.collapsesDescendantsOnCollapse = YES;
    
    MLListFlattenService *service = [[MLListFlattenService alloc] initWithParams:params];
    params.expandBatchCount = 8;
    params.usesFooter = YES;
    params.collapsesDescendantsOnCollapse = NO;
    
    XCTAssertNotEqual(service.params, params);
    XCTAssertEqual(service.params.expandBatchCount, 3);
    XCTAssertFalse(service.params.usesFooter);
    XCTAssertTrue(service.params.collapsesDescendantsOnCollapse);
}

- (void)testStatusDidChangeHandlerIsAppliedToExistingAndNewModels {
    MLTestItem *root = [self itemWithId:@"root"];
    MLListFlattenService *service = [self serviceWithRootItems:@[root]];
    __block NSInteger callCount = 0;
    service.statusDidChangeHandler = ^(__unused MLFlattenedItemModel *changedModel) {
        callCount++;
    };
    
    [self modelInService:service item:root type:MLFlattenedItemTypeCell].status = MLFlattenedItemStatusLoading;
    MLTestItem *inserted = [self itemWithId:@"inserted"];
    [service insertRootItem:inserted position:MLListInsertPositionLast];
    [self modelInService:service item:inserted type:MLFlattenedItemTypeCell].status = MLFlattenedItemStatusLoading;
    
    XCTAssertEqual(callCount, 2);
}

- (void)testStatusChangeHandlerFiresOnlyWhenStatusChanges {
    MLTestItem *root = [self itemWithId:@"root"];
    MLFlattenedItemModel *model = [[MLFlattenedItemModel alloc] initWithDifferableObject:root
                                                                                  parent:nil
                                                                                   level:0
                                                                                    type:MLFlattenedItemTypeCell];
    __block NSInteger callCount = 0;
    model.statusDidChangeHandler = ^(__unused MLFlattenedItemModel *changedModel) {
        callCount++;
    };
    
    model.status = MLFlattenedItemStatusLoading;
    model.status = MLFlattenedItemStatusLoading;
    model.status = MLFlattenedItemStatusLoadFailed;
    
    XCTAssertEqual(callCount, 2);
}

- (void)testDiffEqualityIncludesCountSnapshots {
    MLTestItem *root = [self itemWithId:@"root"];
    root.totalChildrenCount = 3;
    root.visibleChildrenCount = 1;
    MLFlattenedItemModel *oldModel = [[MLFlattenedItemModel alloc] initWithDifferableObject:root
                                                                                    parent:nil
                                                                                     level:0
                                                                                      type:MLFlattenedItemTypeFooter];
    
    root.visibleChildrenCount = 2;
    MLFlattenedItemModel *newModel = [[MLFlattenedItemModel alloc] initWithDifferableObject:root
                                                                                    parent:nil
                                                                                     level:0
                                                                                      type:MLFlattenedItemTypeFooter];
    
    XCTAssertFalse([oldModel isEqualToDiffableObject:newModel]);
}

@end
