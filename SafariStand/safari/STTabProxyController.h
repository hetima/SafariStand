//
//  STTabProxyController.h
//  SafariStand



#import <Foundation/Foundation.h>

@class STPreviewImageManager;

@interface STTabProxyController : NSObject

@property(nonatomic, strong)NSMutableArray* allTabProxy;
@property(nonatomic, strong, readonly)STPreviewImageManager* previewImageManager;

+ (STTabProxyController *)si;
+ (NSMutableArray *)tabProxiesForTabView:(NSTabView*)tabView;
+ (NSMutableArray *)tabProxiesForWindow:(NSWindow*)win;
-(void)setup;
-(void)addTabProxy:(id)tabProxy;
-(void)removeTabProxy:(id)tabProxy;
-(void)maintainTabSelectionOrder:(id)tabProxy;

-(NSTabViewItem*)lastSelectedTabViewItemForwindow:(NSWindow*)win;

@end



