//
//  STTabProxyController.h
//  SafariStand



@import AppKit;

@class STTabProxy;

@interface STTabProxyController : NSObject

@property(nonatomic, strong) NSMutableArray* allTabProxy;

+ (STTabProxyController *)si;
+ (NSMutableArray *)tabProxiesForTabView:(NSTabView*)tabView;
+ (NSMutableArray *)tabProxiesForWindow:(NSWindow*)win;
- (void)setup;
- (void)addTabProxy:(id)tabProxy;
- (void)removeTabProxy:(id)tabProxy;

- (STTabProxy*)tabProxyForPageRef:(void*)pageRef;

- (void)maintainTabSelectionOrder:(id)tabProxy;

-(NSTabViewItem*)lastSelectedTabViewItemForwindow:(NSWindow*)win;

@end

