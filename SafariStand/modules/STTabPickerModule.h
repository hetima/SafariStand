//
//  STTabPickerModule.h
//  SafariStand


@import AppKit;


@interface STTabPickerProxy : NSObject

+ (id)proxyWithVisualTabPickerViewController:(id)ctl;
- (id)initWithVisualTabPickerViewController:(id)ctl;

- (id)visualTabPickerViewController;
- (id)gridView;
- (NSArray*)orderedTabItems;
- (id)thumbnailViewForTabViewItem:(id)tabviewItem;

- (id)firstTabViewItem;
- (id)focusedTabViewItem;
- (id)nextTabViewItem:(id)tabviewItem;
- (id)prevTabViewItem:(id)tabviewItem;
- (void)focusTabViewItem:(id)tabviewItem;
- (void)selectFocusedTab;

@end

@interface STTabPickerModule : STCModule


@end

