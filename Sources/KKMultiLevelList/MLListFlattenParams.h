//
//  MLListFlattenParams.h
//  KKMultiLevelList
//
//  Created by kris cheng on 2026/4/28.
//

#ifndef MLListFlattenParams_h
#define MLListFlattenParams_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MLListItemProtocol;

/// Returns the initial number of visible children for a node.
///
/// This value seeds the framework-owned expansion state the first time a node is
/// seen. Later expand/collapse operations update the internal state instead of
/// writing back to the business model.
typedef NSInteger (^MLListDefaultVisibleChildrenCountProvider)(id<MLListItemProtocol> item,
                                                               NSInteger level,
                                                               id<MLListItemProtocol> _Nullable parentItem);

/// Configuration used when converting tree data into flat list data.
@interface MLListFlattenParams : NSObject <NSCopying>

/// Number of additional children revealed by one expand action.
///
/// Values less than `1` are treated as `1` by the flatten service.
@property (nonatomic, assign) NSInteger expandBatchCount;

/// Default number of visible children for newly seen nodes.
///
/// The default value is `0`. Set this to a positive value to use the same
/// initial count for every node.
@property (nonatomic, assign) NSInteger defaultVisibleChildrenCount;

/// Per-node initial visible child count.
///
/// When provided, this block takes precedence over `defaultVisibleChildrenCount`
/// and can return a different initial count for each node.
@property (nonatomic, nullable, copy) MLListDefaultVisibleChildrenCountProvider defaultVisibleChildrenCountProvider;

/// Whether the service should generate a footer item for nodes with children.
///
/// When enabled, footers can be used by the business layer to render
/// "load more", "collapse", loading, or retry UI.
@property (nonatomic, assign) BOOL usesFooter;

/// Whether collapsing a node should also collapse all descendant nodes.
///
/// When enabled, expanding the node again shows every descendant from a
/// collapsed state instead of restoring its previous expanded child range.
@property (nonatomic, assign) BOOL collapsesDescendantsOnCollapse;

@end

NS_ASSUME_NONNULL_END

#endif /* MLListFlattenParams_h */
