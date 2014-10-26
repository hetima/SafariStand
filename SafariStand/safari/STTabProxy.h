//
//  STTabProxy.h
//  SafariStand



#import <Foundation/Foundation.h>

#define STTabProxyCreatedNote @"STTabProxyCreatedNote"
#define STTabViewDidChangeNote @"STTabViewDidChangeNote"
#define STTabViewDidSelectItemNote @"STTabViewDidSelectItemNote"
#define STTabViewDidReplaceNote @"STTabViewDidReplaceNote"


@class STPreviewImageDelivery;

@interface STTabProxy : NSObject

@property(nonatomic, assign)uintptr_t parentRef;
@property(nonatomic, readonly)uintptr_t ownRef;

@property(nonatomic, assign)BOOL wantsImage;
@property(nonatomic, assign)BOOL isInAnyWidget;
@property(nonatomic, assign)BOOL isMarked;


@property(nonatomic, assign)BOOL isLoading;
@property(nonatomic, assign)BOOL isSelected;
@property(nonatomic, assign, getter=isHidden)BOOL hidden;
@property(nonatomic, assign)BOOL isUnread;
@property(nonatomic, assign)id tabViewItem;
@property(nonatomic, retain)NSImage* cachedImage;
@property(nonatomic, retain)NSString* cachedImageURLString;
@property(nonatomic, retain)NSString* title;
@property(nonatomic, retain)NSString* domain;



+ (STTabProxy*)tabProxyForWKView:(id)wkView;
+ (STTabProxy*)tabProxyForTabViewItem:(id)item;
- (id)initWithTabViewItem:(id)item;
- (void)tabViewItemWillDealloc;

- (void)goToURL:(NSURL*)url;

- (id)window;
- (id)wkView;
- (BOOL)canClose;
- (BOOL)isThereOtherTab;

- (NSString*)URLString;
- (NSString*)imagePathForExt:(NSString*)ext;
- (NSImage*)image;
- (NSImage*)icon;

- (NSTabView *)tabView;
- (void)selectTab;


- (void)didStartProgress;
- (void)didFinishProgress;

- (void)installedToSidebar:(id)ctl;
- (void)uninstalledFromSidebar:(id)ctl;


- (IBAction)actClose:(id)sender;
- (IBAction)actCloseOther:(id)sender;
- (IBAction)actReload:(id)sender;

- (IBAction)actMoveTabToNewWindow:(id)sender;

- (void*)pageRef;

@end

