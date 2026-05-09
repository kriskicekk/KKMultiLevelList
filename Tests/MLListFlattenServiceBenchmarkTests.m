#import <XCTest/XCTest.h>
#import <float.h>

#import "MLListFlattenService.h"
#import "Internal/MLFlattenedItemModelInternal.h"

static const NSInteger MLBenchmarkNodeCount = 50000;
static const NSInteger MLBenchmarkIterations = 5;
static const NSInteger MLLookupThresholdBenchmarkIterations = 10;

typedef void (^MLBenchmarkOperation)(void);
typedef MLBenchmarkOperation (^MLBenchmarkOperationFactory)(void);

@interface MLBenchmarkItem : NSObject <MLListItemProtocol>

@property (nonatomic, strong) id<NSObject> itemId;
@property (nonatomic, nullable, strong) NSMutableArray<id<MLListItemProtocol>> *children;
@property (nonatomic, assign) NSInteger totalChildrenCount;
@property (nonatomic, assign) NSInteger initialVisibleChildrenCount;

@end

@implementation MLBenchmarkItem

- (id<NSObject>)diffIdentifier {
    return self.itemId;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object {
    if (self == object) {
        return YES;
    }
    if (![(id)object isKindOfClass:MLBenchmarkItem.class]) {
        return NO;
    }

    MLBenchmarkItem *item = (MLBenchmarkItem *)object;
    return [self.itemId isEqual:item.itemId]
        && self.children.count == item.children.count
        && self.totalChildrenCount == item.totalChildrenCount
        && self.initialVisibleChildrenCount == item.initialVisibleChildrenCount;
}

@end

@interface MLListFlattenServiceBenchmarkTests : XCTestCase

@end

@implementation MLListFlattenServiceBenchmarkTests

- (MLBenchmarkItem *)itemWithIdentifier:(id<NSObject>)identifier {
    MLBenchmarkItem *item = [[MLBenchmarkItem alloc] init];
    item.itemId = identifier;
    item.children = [NSMutableArray array];
    item.totalChildrenCount = 0;
    item.initialVisibleChildrenCount = 0;
    return item;
}

- (MLBenchmarkItem *)rootWithChildCount:(NSInteger)childCount visibleCount:(NSInteger)visibleCount {
    MLBenchmarkItem *root = [self itemWithIdentifier:@"root"];
    NSMutableArray<id<MLListItemProtocol>> *children = [NSMutableArray arrayWithCapacity:childCount];
    for (NSInteger index = 0; index < childCount; index++) {
        [children addObject:[self itemWithIdentifier:@(index)]];
    }
    root.children = children;
    root.totalChildrenCount = childCount;
    root.initialVisibleChildrenCount = visibleCount;
    return root;
}

- (NSMutableArray<id<MLListItemProtocol>> *)rootItemsWithCount:(NSInteger)count {
    NSMutableArray<id<MLListItemProtocol>> *rootItems = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger index = 0; index < count; index++) {
        [rootItems addObject:[self itemWithIdentifier:@(index)]];
    }
    return rootItems;
}

- (NSMutableArray<id<MLListItemProtocol>> *)rootItemsWithExpandableTailAndVisibleRootCount:(NSInteger)visibleRootCount
                                                                            expandableRoot:(MLBenchmarkItem **)expandableRoot {
    NSMutableArray<id<MLListItemProtocol>> *rootItems = [NSMutableArray arrayWithCapacity:visibleRootCount];
    for (NSInteger index = 0; index < visibleRootCount - 1; index++) {
        [rootItems addObject:[self itemWithIdentifier:@(index)]];
    }

    MLBenchmarkItem *child = [self itemWithIdentifier:@"tail-child"];
    MLBenchmarkItem *tailRoot = [self rootWithChildCount:0 visibleCount:0];
    tailRoot.itemId = @"tail-root";
    tailRoot.children = [@[child] mutableCopy];
    tailRoot.totalChildrenCount = 1;
    tailRoot.initialVisibleChildrenCount = 0;
    [rootItems addObject:tailRoot];

    if (expandableRoot != NULL) {
        *expandableRoot = tailRoot;
    }
    return rootItems;
}

- (NSMutableArray<id<MLListItemProtocol>> *)rootItemsWithExpandableHeadAndVisibleRootCount:(NSInteger)visibleRootCount
                                                                            expandableRoot:(MLBenchmarkItem **)expandableRoot {
    NSMutableArray<id<MLListItemProtocol>> *rootItems = [NSMutableArray arrayWithCapacity:visibleRootCount];
    MLBenchmarkItem *child = [self itemWithIdentifier:@"head-child"];
    MLBenchmarkItem *headRoot = [self rootWithChildCount:0 visibleCount:0];
    headRoot.itemId = @"head-root";
    headRoot.children = [@[child] mutableCopy];
    headRoot.totalChildrenCount = 1;
    headRoot.initialVisibleChildrenCount = 0;
    [rootItems addObject:headRoot];

    for (NSInteger index = 1; index < visibleRootCount; index++) {
        [rootItems addObject:[self itemWithIdentifier:@(index)]];
    }

    if (expandableRoot != NULL) {
        *expandableRoot = headRoot;
    }
    return rootItems;
}

- (MLListFlattenService *)serviceWithRootItems:(NSMutableArray<id<MLListItemProtocol>> *)rootItems
                              expandBatchCount:(NSInteger)expandBatchCount {
    MLListFlattenParams *params = [[MLListFlattenParams alloc] init];
    params.usesFooter = YES;
    params.expandBatchCount = expandBatchCount;
    params.defaultVisibleChildrenCountProvider = ^NSInteger(id<MLListItemProtocol> item,
                                                            __unused NSInteger level,
                                                            __unused id<MLListItemProtocol> parentItem) {
        return ((MLBenchmarkItem *)item).initialVisibleChildrenCount;
    };

    MLListFlattenService *service = [[MLListFlattenService alloc] initWithParams:params];
    service.rootItems = rootItems;
    return service;
}

- (nullable MLFlattenedItemModel *)modelInService:(MLListFlattenService *)service
                                             item:(id<MLListItemProtocol>)item
                                             type:(MLFlattenedItemType)type {
    for (MLFlattenedItemModel *model in service.visibleItems) {
        if (model.differableObject == item && model.type == type) {
            return model;
        }
    }
    return nil;
}

- (nullable MLFlattenedItemModel *)visibleModelByScanningInService:(MLListFlattenService *)service
                                                             model:(MLFlattenedItemModel *)model {
    for (MLFlattenedItemModel *visibleModel in service.visibleItems) {
        BOOL sameObject = visibleModel.differableObject == model.differableObject;
        BOOL sameType = visibleModel.type == model.type;
        if (sameObject && sameType) {
            return visibleModel;
        }
    }
    return nil;
}

- (NSString *)lookupKeyForFlattenedModel:(MLFlattenedItemModel *)model {
    id<NSObject> diffIdentifier = [model.differableObject diffIdentifier];
    if (diffIdentifier == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"%ld-%@", (long)model.type, diffIdentifier];
}

- (MLFlattenedItemModel *)flattenedBenchmarkModelWithIdentifier:(NSString *)identifier {
    MLBenchmarkItem *item = [self itemWithIdentifier:identifier];
    return [[MLFlattenedItemModel alloc] initWithDifferableObject:item
                                                           parent:nil
                                                            level:0
                                                             type:MLFlattenedItemTypeCell
                                             visibleChildrenCount:0];
}

- (NSArray<MLFlattenedItemModel *> *)flattenedBenchmarkModelsWithCount:(NSInteger)count
                                                                prefix:(NSString *)prefix {
    NSMutableArray<MLFlattenedItemModel *> *models = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger index = 0; index < count; index++) {
        NSString *identifier = [NSString stringWithFormat:@"%@-%ld", prefix, (long)index];
        [models addObject:[self flattenedBenchmarkModelWithIdentifier:identifier]];
    }
    return models;
}

- (void)populateLookupIndexes:(NSMutableDictionary<NSString *, NSNumber *> *)indexByKey
                       models:(NSMutableDictionary<NSString *, MLFlattenedItemModel *> *)modelByKey
             withVisibleItems:(NSArray<MLFlattenedItemModel *> *)visibleItems {
    [visibleItems enumerateObjectsUsingBlock:^(MLFlattenedItemModel *model, NSUInteger index, __unused BOOL *stop) {
        NSString *key = [self lookupKeyForFlattenedModel:model];
        if (key != nil) {
            indexByKey[key] = @(index);
            modelByKey[key] = model;
        }
    }];
}

- (NSDictionary<NSString *, NSNumber *> *)benchmarkStatsForOperationFactory:(MLBenchmarkOperationFactory)operationFactory
                                                                 iterations:(NSInteger)iterations {
    NSMutableArray<NSNumber *> *samples = [NSMutableArray arrayWithCapacity:iterations];
    for (NSInteger iteration = 0; iteration < iterations; iteration++) {
        @autoreleasepool {
            MLBenchmarkOperation operation = operationFactory();
            CFAbsoluteTime startedAt = CFAbsoluteTimeGetCurrent();
            operation();
            CFAbsoluteTime elapsedMilliseconds = (CFAbsoluteTimeGetCurrent() - startedAt) * 1000.0;
            [samples addObject:@(elapsedMilliseconds)];
        }
    }

    double total = 0;
    double min = DBL_MAX;
    double max = 0;
    for (NSNumber *sample in samples) {
        double value = sample.doubleValue;
        total += value;
        min = MIN(min, value);
        max = MAX(max, value);
    }
    NSArray<NSNumber *> *sortedSamples = [samples sortedArrayUsingSelector:@selector(compare:)];
    NSUInteger p95Rank = (sortedSamples.count * 95 + 99) / 100;
    NSUInteger p95Index = p95Rank == 0 ? 0 : MIN(sortedSamples.count - 1, p95Rank - 1);
    return @{
        @"avg": @(total / samples.count),
        @"min": @(min),
        @"max": @(max),
        @"p95": sortedSamples[p95Index]
    };
}

- (NSString *)lookupThresholdBenchmarkOutputPath {
    return @"/tmp/kkmultilevel_lookup_threshold_benchmark.txt";
}

- (void)appendLookupThresholdBenchmarkLine:(NSString *)line {
    NSString *lineWithNewline = [line stringByAppendingString:@"\n"];
    NSData *data = [lineWithNewline dataUsingEncoding:NSUTF8StringEncoding];
    NSString *path = [self lookupThresholdBenchmarkOutputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createFileAtPath:path contents:nil attributes:nil];
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle closeFile];
}

- (NSUInteger)lookupBenchmarkLocationForPosition:(NSString *)position
                                     visibleCount:(NSUInteger)visibleCount
                                     rangeLength:(NSUInteger)rangeLength {
    if ([position isEqualToString:@"head"]) {
        return 0;
    }
    if ([position isEqualToString:@"tail"]) {
        return visibleCount - rangeLength;
    }
    return (visibleCount - rangeLength) / 2;
}

- (void)runLookupThresholdBenchmarkNamed:(NSString *)name
                            visibleCount:(NSUInteger)visibleCount
                                position:(NSString *)position
                             rangeLength:(NSUInteger)rangeLength
                        replacementCount:(NSUInteger)replacementCount {
    NSParameterAssert(rangeLength <= visibleCount);
    NSUInteger location = [self lookupBenchmarkLocationForPosition:position
                                                      visibleCount:visibleCount
                                                       rangeLength:rangeLength];
    NSRange range = NSMakeRange(location, rangeLength);
    NSInteger delta = (NSInteger)replacementCount - (NSInteger)rangeLength;
    NSUInteger suffixCount = visibleCount - NSMaxRange(range);
    NSUInteger newVisibleCount = visibleCount + replacementCount - rangeLength;
    NSUInteger changedCount = rangeLength + replacementCount;
    NSUInteger indexShiftCount = delta == 0 ? 0 : suffixCount;
    NSUInteger incrementalWork = indexShiftCount + changedCount * 2;
    NSUInteger rebuildWork = newVisibleCount * 2;
    BOOL heuristicRebuild = incrementalWork >= rebuildWork;

    NSArray<MLFlattenedItemModel *> *oldVisibleItems = [self flattenedBenchmarkModelsWithCount:visibleCount
                                                                                        prefix:[NSString stringWithFormat:@"old-%@-%lu", name, (unsigned long)visibleCount]];
    NSArray<MLFlattenedItemModel *> *replacementItems = [self flattenedBenchmarkModelsWithCount:replacementCount
                                                                                         prefix:[NSString stringWithFormat:@"new-%@-%lu", name, (unsigned long)visibleCount]];
    NSMutableArray<MLFlattenedItemModel *> *newVisibleItems = [oldVisibleItems mutableCopy];
    [newVisibleItems replaceObjectsInRange:range withObjectsFromArray:replacementItems];

    NSMutableDictionary<NSString *, NSNumber *> *baselineIndexByKey = [NSMutableDictionary dictionaryWithCapacity:oldVisibleItems.count];
    NSMutableDictionary<NSString *, MLFlattenedItemModel *> *baselineModelByKey = [NSMutableDictionary dictionaryWithCapacity:oldVisibleItems.count];
    [self populateLookupIndexes:baselineIndexByKey models:baselineModelByKey withVisibleItems:oldVisibleItems];

    NSDictionary<NSString *, NSNumber *> *incrementalStats = [self benchmarkStatsForOperationFactory:^MLBenchmarkOperation{
        NSMutableDictionary<NSString *, NSNumber *> *indexByKey = [baselineIndexByKey mutableCopy];
        NSMutableDictionary<NSString *, MLFlattenedItemModel *> *modelByKey = [baselineModelByKey mutableCopy];
        return ^{
            for (NSUInteger index = range.location; index < NSMaxRange(range); index++) {
                NSString *key = [self lookupKeyForFlattenedModel:oldVisibleItems[index]];
                if (key != nil) {
                    [indexByKey removeObjectForKey:key];
                    [modelByKey removeObjectForKey:key];
                }
            }

            if (delta != 0) {
                for (NSUInteger index = NSMaxRange(range); index < oldVisibleItems.count; index++) {
                    NSString *key = [self lookupKeyForFlattenedModel:oldVisibleItems[index]];
                    if (key != nil && indexByKey[key] != nil) {
                        indexByKey[key] = @((NSInteger)index + delta);
                    }
                }
            }

            [replacementItems enumerateObjectsUsingBlock:^(MLFlattenedItemModel *model, NSUInteger offset, __unused BOOL *stop) {
                NSString *key = [self lookupKeyForFlattenedModel:model];
                if (key != nil) {
                    indexByKey[key] = @(range.location + offset);
                    modelByKey[key] = model;
                }
            }];
        };
    } iterations:MLLookupThresholdBenchmarkIterations];

    NSDictionary<NSString *, NSNumber *> *rebuildStats = [self benchmarkStatsForOperationFactory:^MLBenchmarkOperation{
        return ^{
            NSMutableDictionary<NSString *, NSNumber *> *indexByKey = [NSMutableDictionary dictionaryWithCapacity:newVisibleItems.count];
            NSMutableDictionary<NSString *, MLFlattenedItemModel *> *modelByKey = [NSMutableDictionary dictionaryWithCapacity:newVisibleItems.count];
            [self populateLookupIndexes:indexByKey models:modelByKey withVisibleItems:newVisibleItems];
        };
    } iterations:MLLookupThresholdBenchmarkIterations];

    double incrementalAverage = incrementalStats[@"avg"].doubleValue;
    double rebuildAverage = rebuildStats[@"avg"].doubleValue;
    NSString *winner = incrementalAverage <= rebuildAverage ? @"incremental" : @"rebuild";
    NSString *heuristic = heuristicRebuild ? @"rebuild" : @"incremental";
    double speedup = incrementalAverage <= rebuildAverage ? rebuildAverage / incrementalAverage : incrementalAverage / rebuildAverage;
    NSString *line = [NSString stringWithFormat:@"LOOKUP_THRESHOLD|operation=%@|visible_count=%lu|position=%@|range_length=%lu|replacement_count=%lu|delta=%ld|suffix_count=%lu|changed_count=%lu|incremental_work=%lu|rebuild_work=%lu|heuristic=%@|winner=%@|heuristic_correct=%@|speedup=%.2f|incremental_avg_ms=%.4f|incremental_min_ms=%.4f|incremental_p95_ms=%.4f|rebuild_avg_ms=%.4f|rebuild_min_ms=%.4f|rebuild_p95_ms=%.4f",
                      name,
                      (unsigned long)visibleCount,
                      position,
                      (unsigned long)rangeLength,
                      (unsigned long)replacementCount,
                      (long)delta,
                      (unsigned long)suffixCount,
                      (unsigned long)changedCount,
                      (unsigned long)incrementalWork,
                      (unsigned long)rebuildWork,
                      heuristic,
                      winner,
                      [heuristic isEqualToString:winner] ? @"YES" : @"NO",
                      speedup,
                      incrementalAverage,
                      incrementalStats[@"min"].doubleValue,
                      incrementalStats[@"p95"].doubleValue,
                      rebuildAverage,
                      rebuildStats[@"min"].doubleValue,
                      rebuildStats[@"p95"].doubleValue];
    NSLog(@"%@", line);
    [self appendLookupThresholdBenchmarkLine:line];
}

- (NSString *)benchmarkOutputPath {
    return @"/tmp/kkmultilevel_visible_benchmark.txt";
}

- (void)appendBenchmarkLine:(NSString *)line {
    NSString *lineWithNewline = [line stringByAppendingString:@"\n"];
    NSData *data = [lineWithNewline dataUsingEncoding:NSUTF8StringEncoding];
    NSString *path = [self benchmarkOutputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createFileAtPath:path contents:nil attributes:nil];
    }

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:data];
    [fileHandle closeFile];
}

- (void)runBenchmarkNamed:(NSString *)name operationFactory:(MLBenchmarkOperationFactory)operationFactory {
    NSMutableArray<NSNumber *> *samples = [NSMutableArray arrayWithCapacity:MLBenchmarkIterations];
    for (NSInteger iteration = 0; iteration < MLBenchmarkIterations; iteration++) {
        @autoreleasepool {
            MLBenchmarkOperation operation = operationFactory();
            CFAbsoluteTime startedAt = CFAbsoluteTimeGetCurrent();
            operation();
            CFAbsoluteTime elapsedMilliseconds = (CFAbsoluteTimeGetCurrent() - startedAt) * 1000.0;
            [samples addObject:@(elapsedMilliseconds)];
        }
    }

    double total = 0;
    double min = DBL_MAX;
    double max = 0;
    for (NSNumber *sample in samples) {
        double value = sample.doubleValue;
        total += value;
        min = MIN(min, value);
        max = MAX(max, value);
    }
    double average = total / samples.count;
    NSString *line = [NSString stringWithFormat:@"BENCHMARK|%@|nodes=%ld|iterations=%ld|avg_ms=%.3f|min_ms=%.3f|max_ms=%.3f|samples=%@",
                      name,
                      (long)MLBenchmarkNodeCount,
                      (long)MLBenchmarkIterations,
                      average,
                      min,
                      max,
                      samples];
    NSLog(@"%@", line);
    [self appendBenchmarkLine:line];
}

- (void)testVisibleOperationBenchmarks {
    [[NSFileManager defaultManager] removeItemAtPath:[self benchmarkOutputPath] error:nil];

    [self runBenchmarkNamed:@"expand_root_50000_children" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *root = [self rootWithChildCount:MLBenchmarkNodeCount visibleCount:0];
        MLListFlattenService *service = [self serviceWithRootItems:[@[root] mutableCopy]
                                                  expandBatchCount:MLBenchmarkNodeCount];
        MLFlattenedItemModel *footerModel = [self modelInService:service item:root type:MLFlattenedItemTypeFooter];

        return ^{
            [service appendVisibleChildenItemsForRootModel:footerModel];
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount + 2);
        };
    }];

    [self runBenchmarkNamed:@"collapse_root_50000_children" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *root = [self rootWithChildCount:MLBenchmarkNodeCount visibleCount:MLBenchmarkNodeCount];
        MLListFlattenService *service = [self serviceWithRootItems:[@[root] mutableCopy]
                                                  expandBatchCount:MLBenchmarkNodeCount];
        MLFlattenedItemModel *footerModel = [self modelInService:service item:root type:MLFlattenedItemTypeFooter];

        return ^{
            [service collapseVisibleChildenItemsForRootModel:footerModel];
            XCTAssertEqual(service.visibleItems.count, 2);
        };
    }];

    [self runBenchmarkNamed:@"delete_last_child_from_50000_children" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *root = [self rootWithChildCount:MLBenchmarkNodeCount visibleCount:MLBenchmarkNodeCount];
        MLListFlattenService *service = [self serviceWithRootItems:[@[root] mutableCopy]
                                                  expandBatchCount:MLBenchmarkNodeCount];
        id<MLListItemProtocol> lastChild = root.children.lastObject;
        MLFlattenedItemModel *lastChildModel = [self modelInService:service item:lastChild type:MLFlattenedItemTypeCell];

        return ^{
            [service deleteVisibleChildenItemsForRootModel:lastChildModel];
            XCTAssertEqual(root.children.count, MLBenchmarkNodeCount - 1);
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount + 1);
        };
    }];

    [self runBenchmarkNamed:@"insert_last_child_into_50000_children" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *root = [self rootWithChildCount:MLBenchmarkNodeCount visibleCount:MLBenchmarkNodeCount];
        MLListFlattenService *service = [self serviceWithRootItems:[@[root] mutableCopy]
                                                  expandBatchCount:MLBenchmarkNodeCount];
        MLBenchmarkItem *inserted = [self itemWithIdentifier:@"inserted"];

        return ^{
            [service insertItem:inserted toParentItem:root position:MLListInsertPositionLast];
            XCTAssertEqual(root.children.count, MLBenchmarkNodeCount + 1);
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount + 3);
        };
    }];

    [self runBenchmarkNamed:@"delete_last_root_from_50000_roots" operationFactory:^MLBenchmarkOperation{
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithCount:MLBenchmarkNodeCount];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems
                                                  expandBatchCount:MLBenchmarkNodeCount];
        id<MLListItemProtocol> lastRoot = rootItems.lastObject;
        MLFlattenedItemModel *lastRootModel = [self modelInService:service item:lastRoot type:MLFlattenedItemTypeCell];

        return ^{
            [service deleteVisibleChildenItemsForRootModel:lastRootModel];
            XCTAssertEqual(rootItems.count, MLBenchmarkNodeCount - 1);
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount - 1);
        };
    }];

    [self runBenchmarkNamed:@"resolve_scan_tail_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *tailRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableTailAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&tailRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *tailFooterModel = [self modelInService:service item:tailRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [self visibleModelByScanningInService:service model:tailFooterModel];
            XCTAssertNotNil(currentModel);
        };
    }];

    [self runBenchmarkNamed:@"resolve_map_tail_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *tailRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableTailAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&tailRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *tailFooterModel = [self modelInService:service item:tailRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [service visibleModelMatchingModel:tailFooterModel];
            XCTAssertNotNil(currentModel);
        };
    }];

    [self runBenchmarkNamed:@"resolve_scan_then_append_tail_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *tailRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableTailAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&tailRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *tailFooterModel = [self modelInService:service item:tailRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [self visibleModelByScanningInService:service model:tailFooterModel];
            XCTAssertNotNil(currentModel);
            [service appendVisibleChildenItemsForRootModel:currentModel];
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount + 2);
        };
    }];

    [self runBenchmarkNamed:@"resolve_map_then_append_tail_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *tailRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableTailAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&tailRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *tailFooterModel = [self modelInService:service item:tailRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [service visibleModelMatchingModel:tailFooterModel];
            XCTAssertNotNil(currentModel);
            [service appendVisibleChildenItemsForRootModel:currentModel];
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount + 2);
        };
    }];

    [self runBenchmarkNamed:@"resolve_scan_head_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *headRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableHeadAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&headRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *headFooterModel = [self modelInService:service item:headRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [self visibleModelByScanningInService:service model:headFooterModel];
            XCTAssertNotNil(currentModel);
        };
    }];

    [self runBenchmarkNamed:@"resolve_map_head_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *headRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableHeadAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&headRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *headFooterModel = [self modelInService:service item:headRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [service visibleModelMatchingModel:headFooterModel];
            XCTAssertNotNil(currentModel);
        };
    }];

    [self runBenchmarkNamed:@"resolve_scan_then_append_head_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *headRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableHeadAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&headRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *headFooterModel = [self modelInService:service item:headRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [self visibleModelByScanningInService:service model:headFooterModel];
            XCTAssertNotNil(currentModel);
            [service appendVisibleChildenItemsForRootModel:currentModel];
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount + 2);
        };
    }];

    [self runBenchmarkNamed:@"resolve_map_then_append_head_footer_in_50000_visible_roots" operationFactory:^MLBenchmarkOperation{
        MLBenchmarkItem *headRoot = nil;
        NSMutableArray<id<MLListItemProtocol>> *rootItems = [self rootItemsWithExpandableHeadAndVisibleRootCount:MLBenchmarkNodeCount
                                                                                                 expandableRoot:&headRoot];
        MLListFlattenService *service = [self serviceWithRootItems:rootItems expandBatchCount:1];
        MLFlattenedItemModel *headFooterModel = [self modelInService:service item:headRoot type:MLFlattenedItemTypeFooter];

        return ^{
            MLFlattenedItemModel *currentModel = [service visibleModelMatchingModel:headFooterModel];
            XCTAssertNotNil(currentModel);
            [service appendVisibleChildenItemsForRootModel:currentModel];
            XCTAssertEqual(service.visibleItems.count, MLBenchmarkNodeCount + 2);
        };
    }];
}

- (void)testVisibleLookupMaintenanceThresholdBenchmarks {
    [[NSFileManager defaultManager] removeItemAtPath:[self lookupThresholdBenchmarkOutputPath] error:nil];

    NSArray<NSNumber *> *visibleCounts = @[@128, @512, @1024, @2048, @5000, @10000, @50000];
    for (NSNumber *visibleCountNumber in visibleCounts) {
        @autoreleasepool {
            NSUInteger visibleCount = visibleCountNumber.unsignedIntegerValue;
            NSUInteger tenPercent = MAX((NSUInteger)1, visibleCount / 10);
            NSUInteger half = MAX((NSUInteger)1, visibleCount / 2);

            [self runLookupThresholdBenchmarkNamed:@"replace_one_middle"
                                      visibleCount:visibleCount
                                          position:@"middle"
                                       rangeLength:1
                                  replacementCount:1];

            for (NSString *position in @[@"head", @"middle", @"tail"]) {
                [self runLookupThresholdBenchmarkNamed:@"insert_one"
                                          visibleCount:visibleCount
                                              position:position
                                           rangeLength:0
                                      replacementCount:1];
                [self runLookupThresholdBenchmarkNamed:@"delete_one"
                                          visibleCount:visibleCount
                                              position:position
                                           rangeLength:1
                                      replacementCount:0];
            }

            for (NSString *position in @[@"head", @"tail"]) {
                [self runLookupThresholdBenchmarkNamed:@"delete_10_percent"
                                          visibleCount:visibleCount
                                              position:position
                                           rangeLength:tenPercent
                                      replacementCount:0];
                [self runLookupThresholdBenchmarkNamed:@"delete_half"
                                          visibleCount:visibleCount
                                              position:position
                                           rangeLength:half
                                      replacementCount:0];
            }
        }
    }
}

@end
