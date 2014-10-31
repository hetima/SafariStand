//
//  STTabProxyController.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import "STTabProxy.h"
#import "STTabProxyController.h"

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

    NSMutableArray* ary=[[NSMutableArray alloc]initWithCapacity:32];
    self.allTabProxy=ary;

    //既存のものにパッチ
    STSafariEnumerateBrowserTabViewItem(^(NSTabViewItem* tabViewItem, BOOL* stop){
        //if (STSafariUsesWebKit2(tabViewItem)) {
        STTabProxy* proxy =[[STTabProxy alloc]initWithTabViewItem:tabViewItem];
        if ([[tabViewItem tabView]selectedTabViewItem]==tabViewItem) {
            proxy.isSelected=YES;
        }else{
            proxy.isSelected=NO;
        }
        NSString* URLString=[(id)tabViewItem URLString];
        if (URLString) {
            proxy.host=[[NSURL URLWithString:URLString]host];
        }
        //}
    });

    //tabViewItem を生成するとき STTabProxy を付ける
    Class cls=NSClassFromString(@"BrowserTabViewItem");

    //Safari 8
    if ([cls instancesRespondToSelector:@selector(initWithScrollableTabBarView:browserTab:)]) {
        //- (id)initWithScrollableTabBarView:(id)arg1 browserTab:(struct BrowserTab *)arg2;
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "BrowserTabViewItem",
         "initWithScrollableTabBarView:browserTab:",
         KZRMethodInspection, call, sel,
         ^id (id slf, id tabBarView, void* browserTab)
         {
             id result=call.as_id(slf, sel, tabBarView, browserTab);
             id proxy __unused=[[STTabProxy alloc]initWithTabViewItem:result];
             return result;
             
         });
    }


    //tabの数変更を監視するため
    //順番入れ替えのときは2回呼ばれる(remove->insert)
    KZRMETHOD_SWIZZLING_
    (
     "ScrollableTabBarView", "tabViewDidChangeNumberOfTabViewItems:",
     KZRMethodInspection, call, sel)
     ^(id slf, id /*NSTabView*/ tabView)
    {
         call.as_void(slf, sel, tabView);
         [[NSNotificationCenter defaultCenter]postNotificationName:STTabViewDidChangeNote object:tabView];
     }_WITHBLOCK;


    //tabの選択を監視するため
    KZRMETHOD_SWIZZLING_WITHBLOCK
    (
     "ScrollableTabBarView", "tabView:didSelectTabViewItem:",
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
    /* bookmarks bar の「すべてをタブで開く」などで呼ばれる。NSTabView ごと入れ替わる
       このとき古い NSTabView は「戻る」できるように保持されている。
       そこからページ遷移すると古い NSTabView は破棄され、戻ることもできなくなる。
     */
    KZRMETHOD_SWIZZLING_WITHBLOCK
    (
     "BrowserWindowContentView", "setTabSwitcher:",
     KZRMethodInspection, call, sel,
     ^(id slf, id/*NSTabView*/ tabView)
    {
        //[self willChangeValueForKey:@"allTabProxy"];

        //leftTabs
        NSTabView* exitTabView=objc_msgSend(slf, @selector(tabSwitcher));
        NSArray* exitTabs=[STTabProxyController tabProxiesForTabView:exitTabView];
        [exitTabs enumerateObjectsUsingBlock:^(STTabProxy* obj, NSUInteger idx, BOOL *stop) {
            obj.hidden=YES;
        }];

        call.as_void(slf, sel, tabView);
        
        //[[STTabProxyController si]maintainTabSelectionOrder:[STTabProxy tabProxyForTabViewItem:tabView]];
        //proxy.isSelected がセットされてないことがある
        NSTabViewItem* selectedTabViewItem=[tabView selectedTabViewItem];
        STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:selectedTabViewItem];
        proxy.isSelected=YES;
        
        NSArray* enteredTabs=[STTabProxyController tabProxiesForTabView:tabView];
        [enteredTabs enumerateObjectsUsingBlock:^(STTabProxy* obj, NSUInteger idx, BOOL *stop) {
            obj.hidden=NO;
        }];
        
        //[self didChangeValueForKey:@"allTabProxy"];
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
             [proxy tabViewItemWillDealloc];
             [[STTabProxyController si]removeTabProxy:proxy];
         }
         proxy=nil;
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
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[_allTabProxy count]];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"allTabProxy"];
    [_allTabProxy addObject:tabProxy];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"allTabProxy"];
}

- (void)removeTabProxy:(id)tabProxy
{
    NSInteger idx=[_allTabProxy indexOfObjectIdenticalTo:tabProxy];
    if (idx==NSNotFound) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"tabProxyWillRemove" object:tabProxy];
    NSIndexSet *indexes=[NSIndexSet indexSetWithIndex:idx];
    
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"allTabProxy"];
    [self.allTabProxy removeObjectAtIndex:idx];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"allTabProxy"];
    
}

//not use now
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


