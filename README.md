# KKMultiLevelList

KKMultiLevelList is an Objective-C multi-level list manager built on top of IGListKit. It converts tree-structured business data into a flat IGListKit data source and keeps cell rendering, sizing, selection, and styling in the host app.

## Features

- Tree-to-flat projection for multi-level list data
- Expand, collapse, insert, and delete visible nodes
- Batched child reveal for "load more replies" or "show more children" flows
- Optional footer rows for load more, collapse, loading, and retry states
- UI-free framework surface: business apps provide their own cells and layout

## Installation

Add the pod to your `Podfile`:

```ruby
pod 'KKMultiLevelList'
```

For local development:

```ruby
pod 'KKMultiLevelList', :path => '../KKMultiLevelList'
```

Then run:

```sh
pod install
```

## Usage

Import the framework:

```objc
#import <KKMultiLevelList/KKMultiLevelList.h>
```

Make your model conform to `MLListItemProtocol`, then create an `MLListManager` with an existing `IGListAdapter`:

```objc
IGListAdapterUpdater *updater = [[IGListAdapterUpdater alloc] init];
IGListAdapter *adapter = [[IGListAdapter alloc] initWithUpdater:updater viewController:self];
adapter.collectionView = self.collectionView;

MLListManager *manager = [[MLListManager alloc] initWithAdapter:adapter];
manager.dataSource = self;
manager.delegate = self;
[manager performUpdatesAnimated:NO completion:nil];
```

The data source provides root tree items:

```objc
- (NSArray<id<MLListItemProtocol>> *)objectsForMLListManager:(MLListManager *)listManager {
    return self.items;
}
```

The delegate provides normal cells, footer cells, sizes, selection behavior, and optional insets. See the Example app for a complete integration.

## Project Layout

```text
Sources/KKMultiLevelList/          Framework source files
Examples/KKMultiLevelListExample/  Demo app source files
Tests/                             Unit tests
```

## Example

Open `KKMultiLevelList.xcworkspace` and run the `KKMultiLevelList` scheme. The app target is a demo that uses the framework source directly from `Sources/KKMultiLevelList`.

### Expand More

<img src="https://raw.githubusercontent.com/kriskicekk/KKMultiLevelList/main/Docs/Assets/README/expand-more.gif" alt="Expand more demo" width="280">

### Collapse

<img src="https://raw.githubusercontent.com/kriskicekk/KKMultiLevelList/main/Docs/Assets/README/collapse.gif" alt="Collapse demo" width="280">

### Load More

<img src="https://raw.githubusercontent.com/kriskicekk/KKMultiLevelList/main/Docs/Assets/README/load-more.gif" alt="Load more demo" width="280">

### Delete

<img src="https://raw.githubusercontent.com/kriskicekk/KKMultiLevelList/main/Docs/Assets/README/delete.gif" alt="Delete demo" width="280">

## License

KKMultiLevelList is available under the MIT license. See `LICENSE` for details.
