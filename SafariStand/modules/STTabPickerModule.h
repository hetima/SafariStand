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


@end

@interface STTabPickerModule : STCModule


@end

