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

//tabの数変更を監視する
//順番入れ替えのときは2回呼ばれる(remove->insert)
static void (*orig_tabViewDidChangeNum)(id, SEL, ...); //TabBarView tabViewDidChangeNumberOfTabViewItems:
static void ST_tabViewDidChangeNum(id self, SEL _cmd, id /*NSTabView*/ tabView)
{
	orig_tabViewDidChangeNum(self,_cmd, tabView);
	[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidChangeNote object:tabView];
}

//tabの選択を監視する
static void (*orig_tabViewDidSelectItem)(id, SEL, ...); //TabBarView tabView:didSelectTabViewItem:
static void ST_tabViewDidSelectItem(id self, SEL _cmd, id tabView, id item)
{
    orig_tabViewDidSelectItem(self,_cmd, tabView, item);
    
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
    
	[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidSelectItemNote object:tabView];
}

//TabBarView - (void)replaceTabView:(id)arg1;
//tabView入れ替わりを監視
//bookmarks bar の「すべてをタブで開く」などで呼ばれる。NSTabView ごと入れ替わる
static void (*orig_replaceTabView)(id, SEL, ...);
static void ST_replaceTabView(id self, SEL _cmd, id/*NSTabView*/ tabView)
{
    orig_replaceTabView(self, _cmd, tabView);
    //[[STTabProxyController si]maintainTabSelectionOrder:[STTabProxy tabProxyForTabViewItem:tabView]];
    //proxy.isSelected がセットされてないことがある
    NSTabViewItem* selectedTabViewItem=[tabView selectedTabViewItem];
    STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:selectedTabViewItem];
    proxy.isSelected=YES;
    
	[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidReplaceNote object:tabView]; //重要：こっちが先
	//[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidChangeNote object:tabView];
    
}

//tabViewItem を生成するとき STTabProxy を付ける
static id (*orig_initWithTabBarView)(id, SEL, ...);
static id ST_initWithTabBarView(id self, SEL _cmd, id tabBarView, BOOL useWebKit2, void* tab)
{
    id result=orig_initWithTabBarView(self, _cmd, tabBarView, useWebKit2, tab);
    if(useWebKit2){
        id proxy __unused=[[STTabProxy alloc]initWithTabViewItem:result];
    }
    return result;
}

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

//tabViewItem がdealloc、 STTabProxyリストから除外
static void (*orig_tabViewItem_dealloc)(id, SEL);
//重要：dealloc 中 retain されないように self は __unsafe_unretained
static void ST_tabViewItem_dealloc(__unsafe_unretained id self, SEL _cmd)
{
    id proxy=[STTabProxy tabProxyForTabViewItem:self];
    if(proxy){
        [[STTabProxyController si]removeTabProxy:proxy];
    }
    orig_tabViewItem_dealloc(self, _cmd);
}



//STTabProxy の title を更新
static void (*orig_setLabel)(id, SEL, ...);
static void ST_setLabel(id self, SEL _cmd, NSString* label)
{
    orig_setLabel(self, _cmd, label);

    STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:self];
    proxy.title=label;
}


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
                //if ([tabViewItem respondsToSelector:@selector(usesWebKit2)] && objc_msgSend(tabViewItem, @selector(usesWebKit2))) {
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
    orig_initWithTabBarView = (id(*)(id, SEL, ...))RMF(NSClassFromString(@"BrowserTabViewItem"),
                                @selector(initWithTabBarView:useWebKit2:withBrowserTab:), ST_initWithTabBarView);

    //tabの数変更を監視するため
    orig_tabViewDidChangeNum = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"TabBarView"),
                                @selector(tabViewDidChangeNumberOfTabViewItems:), ST_tabViewDidChangeNum);
    //tabの選択を監視するため
    orig_tabViewDidSelectItem = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"TabBarView"),
                                @selector(tabView:didSelectTabViewItem:), ST_tabViewDidSelectItem);

    //tabView入れ替わりを監視するため
    orig_replaceTabView = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"TabBarView"),
                                @selector(replaceTabView:), ST_replaceTabView);

    
    //STTabProxy の title を更新するため
    orig_setLabel = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"BrowserTabViewItem"),
                                @selector(setLabel:), ST_setLabel);
    
    //STTabProxyをリストから除外するため
//    orig_removeTabViewItem = RMF(NSClassFromString(kSafariBrowserWindowController),
//                              @selector(_removeTabViewItem:), ST_removeTabViewItem);
    orig_tabViewItem_dealloc = (void(*)(id, SEL))RMF(NSClassFromString(@"BrowserTabViewItem"),
                                NSSelectorFromString(@"dealloc"), ST_tabViewItem_dealloc);

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
        if ([tabViewItem respondsToSelector:@selector(usesWebKit2)] && objc_msgSend(tabViewItem, @selector(usesWebKit2))) {
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
            if ([tabViewItem respondsToSelector:@selector(usesWebKit2)] && objc_msgSend(tabViewItem, @selector(usesWebKit2))) {
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


