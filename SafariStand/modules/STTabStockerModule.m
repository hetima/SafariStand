//
//  STTabStockerModule.m
//  SafariStand


#import "SafariStand.h"
#import "STTabStockerModule.h"
#import "STTabProxy.h"
#import "HTSymbolHook.h"

id STSafariBrowserTabPersistentStateWithBrowserTab(void* browserTab)
{
    Class aClass=NSClassFromString(@"BrowserTabPersistentState");
    if (!browserTab || ![aClass instancesRespondToSelector:@selector(initWithBrowserTab:)]) {
        return nil;
    }
    id result=((id(*)(id, SEL, ...))objc_msgSend)([aClass alloc], @selector(initWithBrowserTab:), browserTab);
    
    return result;
}

@implementation STTabStockerModule {
    NSMenuItem* _reopenLastTabItem;
    NSMenuItem* _closedTabsItem;
    NSString* _menuGroupName;
    void (*_restoreFromBrowserTabState)(const void*, id, BOOL);
}

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (!self) return nil;
    
    _menuGroupName=@"2000-ClosedTabs";
    _closedTabs=[[NSMutableArray alloc]initWithCapacity:20];
    
    HTSymbolHook* hook=[HTSymbolHook symbolHookWithImageNameSuffix:@"/Safari.framework/Versions/A/Safari"];
    _restoreFromBrowserTabState=[hook symbolPtrWithSymbolName:@"__ZN6Safari10BrowserTab26restoreFromBrowserTabStateEP25BrowserTabPersistentStateNS_15AllowJavaScriptE"];
    

    //normal close
    KZRMETHOD_SWIZZLING_("BrowserWindowControllerMac", "_closeTabWithoutConfirming:",
                         void, call, sel)
    ^(id slf, id tabViewItem)
    {
        if ([[STCSafariStandCore ud]integerForKey:kpClosedTabQuantities]) {
            BOOL usesPrivateBrowsing=NO;
            if ([slf respondsToSelector:@selector(usesPrivateBrowsing)]) {
                usesPrivateBrowsing=((BOOL (*)(id, SEL, ...))objc_msgSend)(slf, @selector(usesPrivateBrowsing));
            }

            if (!usesPrivateBrowsing) {
                [self addBrowserTabViewItem:tabViewItem];
            }
        }
        call(slf, sel, tabViewItem);
        
    }_WITHBLOCK;
    
    //close other tab
    KZRMETHOD_SWIZZLING_("BrowserWindowControllerMac", "_closeOtherTabsWithoutConfirming:", void, call, sel)
    ^(id slf, id arg1)
    {
        if ([[STCSafariStandCore ud]integerForKey:kpClosedTabQuantities]) {
            BOOL usesPrivateBrowsing=NO;
            if ([slf respondsToSelector:@selector(usesPrivateBrowsing)]) {
                usesPrivateBrowsing=((BOOL (*)(id, SEL, ...))objc_msgSend)(slf, @selector(usesPrivateBrowsing));
            }
            
            if(!usesPrivateBrowsing && [slf respondsToSelector:@selector(orderedTabViewItems)]){
                NSArray* tabs=objc_msgSend(slf, @selector(orderedTabViewItems));
                for (id tabViewItem in tabs) {
                    if (tabViewItem != arg1) {
                        [self addBrowserTabViewItem:tabViewItem];
                    }
                }
            }
        }
        call(slf, sel, arg1);
        
    }_WITHBLOCK;
    
    //close window
    KZRMETHOD_SWIZZLING_("BrowserWindowControllerMac", "windowWillClose:", void, call, sel)
    ^(id slf, id arg1)
    {
        if ([[STCSafariStandCore ud]integerForKey:kpClosedTabQuantities]) {
            BOOL usesPrivateBrowsing=NO;
            if ([slf respondsToSelector:@selector(usesPrivateBrowsing)]) {
                usesPrivateBrowsing=((BOOL (*)(id, SEL, ...))objc_msgSend)(slf, @selector(usesPrivateBrowsing));
            }
            
            if(!usesPrivateBrowsing && [slf respondsToSelector:@selector(orderedTabViewItems)]){
                NSArray* tabs=objc_msgSend(slf, @selector(orderedTabViewItems));
                for (id tabViewItem in tabs) {
                    [self addBrowserTabViewItem:tabViewItem];
                }
            }
        }
        call(slf, sel, arg1);
        
    }_WITHBLOCK;


    [self setupMenu:core];
    [self updateMenu];
    [self observePrefValue:kpClosedTabQuantities];
    
    return self;
}


- (void)setupMenu:(STCSafariStandCore*)core
{
    _reopenLastTabItem=[[NSMenuItem alloc]initWithTitle:@"Reopen Last Closed Tab" action:@selector(actReopenLastClosedTab:) keyEquivalent:@""];
    [_reopenLastTabItem setTarget:self];
    
    _closedTabsItem=[[NSMenuItem alloc]initWithTitle:@"Reopen Closed Tab" action:nil keyEquivalent:@""];
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@""];
    menu.delegate=self;
    [_closedTabsItem setSubmenu:menu];

    [core addGroupToStandMenu:@[[NSMenuItem separatorItem], _reopenLastTabItem, _closedTabsItem, [NSMenuItem separatorItem]] name:_menuGroupName];
}


- (void)updateMenu
{
    [_closedTabsItem.submenu removeAllItems];

    if ([_closedTabs count]<=0) {
        _closedTabsItem.hidden=YES;
    }else{
        _closedTabsItem.hidden=NO;
    }
}


- (void)menuNeedsUpdate:(NSMenu*)menu;
{
    [menu removeAllItems];
    for (STBrowserTabPersistentStateProxy* proxy in _closedTabs) {
        NSMenuItem* itm=[menu addItemWithTitle:proxy.label action:@selector(actMenuSelected:) keyEquivalent:@""];
        [itm setTarget:self];
        [itm setRepresentedObject:proxy];
        [itm setImage:proxy.icon];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem* itm=[menu addItemWithTitle:@"Clear History" action:@selector(actClearHistory:) keyEquivalent:@""];
    [itm setTarget:self];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action]==@selector(actReopenLastClosedTab:)) {
        return ([_closedTabs count]>0) ? YES:NO;
    }
    return YES;
}


- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpClosedTabQuantities]){
        [self fitQuantity];
        [self updateMenu];
    }
}


- (void)fitQuantity
{
    NSInteger limit=[[STCSafariStandCore ud]integerForKey:kpClosedTabQuantities];
    if (limit<0) {
        limit=0;
    }
    NSInteger cnt=[_closedTabs count];
    
    if (limit==0) {
        self.closedTabs=[[NSMutableArray alloc]init];
    }else if (cnt>limit) {
        NSMutableArray* ary=[[_closedTabs subarrayWithRange:NSMakeRange(0, limit)]mutableCopy];
        self.closedTabs=ary;
    }
}


- (void)addBrowserTabViewItem:(id)tabViewItem
{
    void* browserTab=STSafariStructBrowserTabForTabViewItem(tabViewItem);
    id state=STSafariBrowserTabPersistentStateWithBrowserTab(browserTab);
    
    if (![state url]) {
        return;
    }
    
    NSMutableArray* ary=[self mutableArrayValueForKey:@"closedTabs"];
    STBrowserTabPersistentStateProxy* proxy=[[STBrowserTabPersistentStateProxy alloc]initWithBrowserTabPersistentState:state];
    
    //icon
    //閉じる直前なので tabProxy.icon はもう他では使われない。copy せずそのまま setSize: して構わない
    STTabProxy* tabProxy=[STTabProxy tabProxyForTabViewItem:tabViewItem];
    NSImage* icon=tabProxy.icon;
    if (!icon) {
        icon=[NSImage imageNamed:@"NSToolbarBookmarks"];
    }
    if (icon) {
        [icon setSize:NSMakeSize(16.0f, 16.0f)];
    }
    proxy.icon=icon;
    
    [ary insertObject:proxy atIndex:0];
    NSInteger limit=[[STCSafariStandCore ud]integerForKey:kpClosedTabQuantities];
    if ([ary count]>limit) {
        [ary removeLastObject];
    }
    [self updateMenu];
}


#pragma mark -

- (void)actClearHistory:(id)sender
{
    self.closedTabs=[[NSMutableArray alloc]init];
    [self updateMenu];
}


- (void)actReopenLastClosedTab:(NSMenuItem*)sender
{
    STBrowserTabPersistentStateProxy* proxy=[_closedTabs firstObject];
    [self restoreTabOrWindow:proxy];
}


- (void)actMenuSelected:(NSMenuItem*)sender
{
    STBrowserTabPersistentStateProxy* proxy=[sender representedObject];
    [self restoreTabOrWindow:proxy];
}


- (void)restoreTabOrWindow:(STBrowserTabPersistentStateProxy*)proxy
{
    if ([proxy isKindOfClass:[STBrowserTabPersistentStateProxy class]]) {
        id tab=STSafariCreateEmptyTab();
        void* browserTab=STSafariStructBrowserTabForTabViewItem(tab);
        id state=proxy.browserTabPersistentState;
        if (browserTab && state && _restoreFromBrowserTabState) {
            _restoreFromBrowserTabState(browserTab, state, NO);
        }
    }
    
    NSMutableArray* ary=[self mutableArrayValueForKey:@"closedTabs"];
    [ary removeObjectIdenticalTo:proxy];
    [self updateMenu];
}

@end



@implementation STBrowserTabPersistentStateProxy

@dynamic label;

- (instancetype)initWithBrowserTabPersistentState:(id)state
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _browserTabPersistentState=state;
    _icon=nil;
    _date=[NSDate date];
    
    return self;
}


- (NSString*)label
{
    NSString* title=[_browserTabPersistentState title];
    NSInteger secs=abs((int)[_date timeIntervalSinceNow]);
    NSString* time=[NSString stand_timeStringFromSecs:secs];
    NSString* label=[NSString stringWithFormat:@"%@ [%@]", title, time];
    
    return label;
}


@end

