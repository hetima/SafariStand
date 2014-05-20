//
//  STTabProxyController.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import "STTabProxy.h"
#import "STTabProxyController.h"
#import "STPreviewImageManager.h"

//#import <WebKit2/WKImage.h>
//#import <WebKit2/WKImageCG.h>
//#import <WebKit2/WKBundlePage.h>

#import "HTWebKit2Adapter.h"


@implementation STTabProxyController


static STTabProxyController *sharedInstance;

//未使用
//tabViewItem が取り除かれるとき STTabProxyリストから除外
/*
 static void (*orig_removeTabViewItem)(id, SEL, ...);
static void ST_removeTabViewItem(id self, SEL _cmd, id tabViewItem)
{
    id proxy=[STTabProxy tabProxyForTabViewItem:tabViewItem];
    if(proxy){
        [NSObject cancelPreviousPerformRequestsWithTarget:proxy
                                                 selector:@selector(updateImage) object:nil];

        [[STTabProxyController si]removeTabProxy:proxy];
    }
    orig_removeTabViewItem(self, _cmd, tabViewItem);
}
*/


- (void)setup
{
    _previewImageManager=[[STPreviewImageManager alloc]init];

    NSMutableArray* ary=[[NSMutableArray alloc]initWithCapacity:32];
    self.allTabProxy=ary;

    //既存のものにパッチ
    NSArray* windows=[NSApp windows];
    for (NSWindow* win in windows) {
        id winCtl=[win windowController];
        if([[winCtl className]isEqualToString:kSafariBrowserWindowController]
           && [winCtl respondsToSelector:@selector(orderedTabViewItems)]){
            NSArray* tabs=objc_msgSend(winCtl, @selector(orderedTabViewItems));
            for (id tabViewItem in tabs) {
                //if (STSafariUsesWebKit2(tabViewItem)) {
                STTabProxy* proxy =[[STTabProxy alloc]initWithTabViewItem:tabViewItem];
                if ([[tabViewItem tabView]selectedTabViewItem]==tabViewItem) {
                    proxy.isSelected=YES;
                }else{
                    proxy.isSelected=NO;
                }
                //}
            }
        }
    }
    

    //tabViewItem を生成するとき STTabProxy を付ける
    //Safari 6
    Class cls=NSClassFromString(@"BrowserTabViewItem");
    if ([cls instancesRespondToSelector:@selector(initWithTabBarView:useWebKit2:withBrowserTab:)]) {

        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "BrowserTabViewItem",
         "initWithTabBarView:useWebKit2:withBrowserTab:",
         KZRMethodInspection, call, sel,
         ^id (id slf, id tabBarView, BOOL useWebKit2, void* tab)
        {
             id result=call.as_id(slf, sel, tabBarView, useWebKit2, tab);
             if(useWebKit2){
                 id proxy __unused=[[STTabProxy alloc]initWithTabViewItem:result];
             }
             return result;
         });

    //Safari 7
    }else if ([cls instancesRespondToSelector:@selector(initWithTabBarView:withBrowserTab:andIdentifier:)]) {
        //- (id)initWithTabBarView:(id)arg1 withBrowserTab:(struct BrowserTab *)arg2 andIdentifier:(unsigned long long)arg3;
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "BrowserTabViewItem",
         "initWithTabBarView:withBrowserTab:andIdentifier:",
         KZRMethodInspection, call, sel,
         ^id (id slf, id tabBarView, void* browserTab, unsigned long long identifier)
        {
             id result=call.as_id(slf, sel, tabBarView, browserTab, identifier);
             id proxy __unused=[[STTabProxy alloc]initWithTabViewItem:result];
             return result;

         });
    }

    
    //tabの数変更を監視するため
    //順番入れ替えのときは2回呼ばれる(remove->insert)
    KZRMETHOD_SWIZZLING_WITHBLOCK
    (
     "TabBarView", "tabViewDidChangeNumberOfTabViewItems:",
     KZRMethodInspection, call, sel,
     ^(id slf, id /*NSTabView*/ tabView)
    {
         call.as_void(slf, sel, tabView);
         [[NSNotificationCenter defaultCenter]postNotificationName:STTabViewDidChangeNote object:tabView];
     });


    //tabの選択を監視するため
    KZRMETHOD_SWIZZLING_WITHBLOCK
    (
     "TabBarView", "tabView:didSelectTabViewItem:",
     KZRMethodInspection, call, sel,
     ^(id slf, id tabView, id item)
    {
         call.as_void(slf, sel, tabView, item);
         
         NSArray* tabViewItems=[tabView tabViewItems];
         for (NSTabViewItem* eachItem in tabViewItems) {
             STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:eachItem];
             if (eachItem==item) {
                 proxy.isUnread=NO;
                 proxy.isSelected=YES;
             }else if (proxy.isSelected){
                 proxy.isSelected=NO;
             }
         }
         
         [[NSNotificationCenter defaultCenter]postNotificationName:STTabViewDidSelectItemNote object:tabView];

     });


    //tabView入れ替わりを監視するため
    //bookmarks bar の「すべてをタブで開く」などで呼ばれる。NSTabView ごと入れ替わる
    KZRMETHOD_SWIZZLING_WITHBLOCK
    (
     "TabBarView", "replaceTabView:",
     KZRMethodInspection, call, sel,
     ^(id slf, id/*NSTabView*/ tabView)
    {
         call.as_void(slf, sel, tabView);
         //[[STTabProxyController si]maintainTabSelectionOrder:[STTabProxy tabProxyForTabViewItem:tabView]];
         //proxy.isSelected がセットされてないことがある
         NSTabViewItem* selectedTabViewItem=[tabView selectedTabViewItem];
         STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:selectedTabViewItem];
         proxy.isSelected=YES;
         
         [[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidReplaceNote object:tabView]; //重要：こっちが先
         //[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidChangeNote object:tabView];
     });


    //STTabProxy の title を更新するため
    KZRMETHOD_SWIZZLING_WITHBLOCK
    (
     "BrowserTabViewItem", "setLabel:",
     KZRMethodInspection, call, sel,
     ^(id slf, NSString* label)
    {
        call.as_void(slf, sel, label);

        STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:slf];
        proxy.title=label;
     });


    //STTabProxyをリストから除外するため
//    orig_removeTabViewItem = RMF(NSClassFromString(kSafariBrowserWindowController),
//                              @selector(_removeTabViewItem:), ST_removeTabViewItem);
    
    //tabViewItem がdealloc、 STTabProxyリストから除外
    //重要：dealloc 中 retain されないように self は __unsafe_unretained
    KZRMETHOD_SWIZZLING_WITHBLOCK
    (
     "BrowserTabViewItem", "dealloc",
     KZRMethodInspection, call, sel,
     ^(__unsafe_unretained id slf){
         
         id proxy=[STTabProxy tabProxyForTabViewItem:slf];
         if(proxy){
             [[STTabProxyController si]removeTabProxy:proxy];
         }
         call.as_void(slf, sel);
     });
    
}

+ (STTabProxyController *)si
{
    if (sharedInstance == nil) {
		sharedInstance = [[STTabProxyController alloc]init];
        [sharedInstance setup];
    }
    
    return sharedInstance;
}

+ (NSMutableArray *)tabProxiesForTabView:(NSTabView*)tabView
{
    NSMutableArray* ary=nil;
    NSArray* tabs=[tabView tabViewItems];
    ary=[NSMutableArray arrayWithCapacity:[tabs count]];
    for (id tabViewItem in tabs) {
        if (STSafariUsesWebKit2(tabViewItem)) {
            id proxy=[STTabProxy tabProxyForTabViewItem:tabViewItem];
            if (proxy) {
                [ary addObject:proxy];
            }
        }
    }
    return ary;

}

+ (NSMutableArray *)tabProxiesForWindow:(NSWindow*)win
{
    NSMutableArray* ary=nil;
    id winCtl=[win windowController];
    if([[winCtl className]isEqualToString:kSafariBrowserWindowController]
       && [winCtl respondsToSelector:@selector(orderedTabViewItems)]){
        NSArray* tabs=objc_msgSend(winCtl, @selector(orderedTabViewItems));
        
        ary=[NSMutableArray arrayWithCapacity:[tabs count]];
        for (id tabViewItem in tabs) {
            if (STSafariUsesWebKit2(tabViewItem)) {
                id proxy=[STTabProxy tabProxyForTabViewItem:tabViewItem];
                if (proxy) {
                    [ary addObject:proxy];
                }
            }
        }
    }
    return ary;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (STTabProxy*)tabProxyForPageRef:(void*)pageRef
{
    for (STTabProxy* tabProxy in _allTabProxy) {
        if ([tabProxy pageRef]==pageRef) {
            return tabProxy;
        }
    }
    return nil;
}

-(void)addTabProxy:(id)tabProxy
{
    [self.allTabProxy addObject:tabProxy];
}

- (void)removeTabProxy:(id)tabProxy
{
    NSInteger idx=[self.allTabProxy indexOfObjectIdenticalTo:tabProxy];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"tabProxyWillRemove" object:tabProxy];
    if (idx!=NSNotFound) {
        [self.allTabProxy removeObjectAtIndex:idx];
    }
    
}

-(void)maintainTabSelectionOrder:(id)tabProxy
{
    if (tabProxy) {
        [self.allTabProxy removeObject:tabProxy];
        [self.allTabProxy addObject:tabProxy];
    }
}

-(NSTabViewItem*)lastSelectedTabViewItemForwindow:(NSWindow*)win
{
    NSTabViewItem* result=nil;
    NSEnumerator* e=[self.allTabProxy reverseObjectEnumerator];
    STTabProxy* tabProxy=nil;
    while (tabProxy=[e nextObject]) {
        if ([[tabProxy tabView]window]==win) {
            result=[tabProxy tabViewItem];
            break;
        }
    }
    return result;
}

@end


