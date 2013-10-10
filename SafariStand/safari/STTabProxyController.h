//
//  STTabProxyController.h
//  SafariStand



#import <Foundation/Foundation.h>

@interface STTabProxyController : NSObject

@property(nonatomic, retain)NSMutableArray* allTabProxy;

+ (STTabProxyController *)si;
+ (NSMutableArray *)tabProxiesForTabView:(NSTabView*)tabView;
+ (NSMutableArray *)tabProxiesForWindow:(NSWindow*)win;
-(void)setup;
-(void)addTabProxy:(id)tabProxy;
-(void)removeTabProxy:(id)tabProxy;
-(void)maintainTabSelectionOrder:(id)tabProxy;

-(NSTabViewItem*)lastSelectedTabViewItemForwindow:(NSWindow*)win;

@end



