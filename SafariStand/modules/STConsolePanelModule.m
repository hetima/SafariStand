//
//  STConsolePanelModule.m
//  SafariStand


#import "SafariStand.h"
#import "STConsolePanelModule.h"
#import "STCTabListViewCtl.h"

#define kpConsolePanelToolbarIdentifier @"NSToolbar Configuration Stand_ConsolePanelToolbar"

@implementation STConsolePanelModule {
    STConsolePanelCtl* _winCtl;
}


-(id)initWithStand:(STCSafariStandCore*)core
{
    self = [super initWithStand:core];
    if (self) {
        //[self observePrefValue:];
        _winCtl=nil;
        _panels=[[NSMutableDictionary alloc]initWithCapacity:8];

        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Console Panel" action:@selector(actShowConsolePanel:) keyEquivalent:@"k"];
        [itm setKeyEquivalentModifierMask:NSCommandKeyMask|NSAlternateKeyMask];
        [itm setTarget:self];
        [itm setTag:kMenuItemTagConsolePanel];
        [core addItemToStandMenu:itm];
    }
    return self;
}


- (void)modulesDidFinishLoading:(id)core
{
    [self addSafariBookmarksView];
    [self addTabListViewView];
}


- (void)dealloc
{

}


- (void)prefValue:(NSString*)key changed:(id)value
{
    if([key isEqualToString:kpConsolePanelToolbarIdentifier]){
        if(value)[[STCSafariStandCore si]setObject:value forKey:kpConsolePanelToolbarConfigurationBackup];
        [[STCSafariStandCore si]synchronize];
    }}


- (IBAction)actShowConsolePanel:(id)sender
{
    [self showConsolePanelAndSelectTab:nil];
}


- (void)showConsolePanelAndSelectTab:(NSString*)identifier
{
    if(!_winCtl){
        _winCtl=[[STConsolePanelCtl alloc]initWithWindowNibName:@"STConsolePanel"];
        [_winCtl commonConsolePanelCtlInitWithModule:self];
        [self observePrefValue:kpConsolePanelToolbarIdentifier]; //after toolbar created
    }

    [_winCtl selectTab:identifier];
    [_winCtl showWindow:self];
    
}


- (void)addPanelWithIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight loadHandler:(id(^)())loadHandler
{
    NSDictionary* panel=@{@"identifier":identifier, @"title":title, @"icon":icon,  @"weight":@(weight), @"loadHandler":loadHandler};
    _panels[identifier]=panel;
}


- (NSDictionary*)panelInfoForIdentifier:(NSString*)identifier
{
    return _panels[identifier];
}


- (void)addTabListViewView
{
    STConsolePanelModule* consolePanelModule=[STCSafariStandCore mi:@"STConsolePanelModule"];
    //NSImage* img=[NSImage imageNamed:@"NSPrivateChaptersTemplate"];
    NSImage* img=[[NSImage alloc]initWithContentsOfFile:@"/System/Library/Frameworks/OSAKit.framework/Versions/A/Resources/osa_suites.pdf"];
    [img setTemplate:YES];
    //[img setSize:NSMakeSize(16.0, 16.0)];
    
    [consolePanelModule addPanelWithIdentifier:@"TabList" title:@"Tab List" icon:img weight:1 loadHandler:^id{
        STCTabListViewCtl* viewCtl=[STCTabListViewCtl viewCtl];
        return viewCtl;
    }];
    
}
#pragma mark - Bookmarks

+ (NSURL*)selectedURLOnSafariBookmarksView:(id)bookmarksSidebarViewController
{
    if (![bookmarksSidebarViewController respondsToSelector:@selector(_selectedBookmarks)]) {
        return nil;
    }
    id bookmarkLeaf=[objc_msgSend(bookmarksSidebarViewController, @selector(_selectedBookmarks)) firstObject];
    
    NSString* str=STSafariWebBookmarkURLString(bookmarkLeaf);
    if ([str length]<=0) {
        return nil;
    }
    
    return [str stand_httpOrFileURL];
}


- (void)addSafariBookmarksView
{
    NSImage* img=STSafariBundleImageNamed(@"SB_ModernTabIconBookmarks");
    [img setTemplate:YES];
    [self addPanelWithIdentifier:@"Bookmarks" title:@"Bookmarks" icon:img weight:2 loadHandler:^id{
        id bookmarksViewController=objc_msgSend([NSClassFromString(@"BookmarksSidebarViewController") alloc], @selector(initWithNibName:bundle:), nil, nil);
        return bookmarksViewController;
    }];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //click
        KZRMETHOD_SWIZZLING_
        (
         "BookmarksSidebarViewController",
         "_openBookmarkAndGiveFocusToWebContent:", //BookmarkLeaf
         KZRMethodInspection, call, sel)
        ^void (id slf, id bookmarkLeaf){
            if ([[[slf view]window]isKindOfClass:[STConsolePanelWindow class]]) {
                NSURL* url=[STSafariWebBookmarkURLString(bookmarkLeaf) stand_httpOrFileURL];
                if(url)STSafariGoToURLWithPolicy(url, poNormal);
            }else{
                call.as_void(slf, sel, bookmarkLeaf);
            }
            
        }_WITHBLOCK;
        
        //context menu
        KZRMETHOD_SWIZZLING_
        (
         "BookmarksSidebarViewController",
         "_openInCurrentTab:",
         KZRMethodInspection, call, sel)
        ^void (id slf, id obj){
            if ([[[slf view]window]isKindOfClass:[STConsolePanelWindow class]]) {
                NSURL* url=[STConsolePanelModule selectedURLOnSafariBookmarksView:slf];
                if(url)STSafariGoToURLWithPolicy(url, poNormal);
            }else{
                call.as_void(slf, sel, obj);
            }
            
        }_WITHBLOCK;
        
        KZRMETHOD_SWIZZLING_
        (
         "BookmarksSidebarViewController",
         "_openInNewTab:",
         KZRMethodInspection, call, sel)
        ^void (id slf, id obj){
            if ([[[slf view]window]isKindOfClass:[STConsolePanelWindow class]]) {
                NSURL* url=[STConsolePanelModule selectedURLOnSafariBookmarksView:slf];
                if(url)STSafariGoToURLWithPolicy(url, poNewTab);
            }else{
                call.as_void(slf, sel, obj);
            }
            
        }_WITHBLOCK;
        
        KZRMETHOD_SWIZZLING_
        (
         "BookmarksSidebarViewController",
         "_openInNewWindow:",
         KZRMethodInspection, call, sel)
        ^void (id slf, id obj){
            if ([[[slf view]window]isKindOfClass:[STConsolePanelWindow class]]) {
                NSURL* url=[STConsolePanelModule selectedURLOnSafariBookmarksView:slf];
                if(url)STSafariGoToURLWithPolicy(url, poNewWindow);
            }else{
                call.as_void(slf, sel, obj);
            }
            
        }_WITHBLOCK;
        
    });
    
}


@end


@implementation STConsolePanelCtl{
    NSMutableArray* _viewCtlPool;
    NSString* _landingItemIdentifier;
    NSArray* _defaultItemIdentifiers;
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
    }
    return self;
}


- (void)commonConsolePanelCtlInitWithModule:(STConsolePanelModule*)consolePanelModule
{
    _landingItemIdentifier=nil;
    _viewCtlPool=[[NSMutableArray alloc]initWithCapacity:8];
    self.consolePanelModule=consolePanelModule;
    
    NSDictionary* panelInfo=consolePanelModule.panels;
    [self.identifiers addObjectsFromArray:[panelInfo allKeys]];

    
    //construct default items
    NSMutableArray* defaultItemsInfo=[[NSMutableArray alloc]initWithCapacity:[panelInfo count]];
    [panelInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([obj[@"weight"] integerValue]>0){
            [defaultItemsInfo addObject:obj];
        }
    }];
    [defaultItemsInfo sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber* n1=obj1[@"weight"];
        NSNumber* n2=obj2[@"weight"];
        return [n1 compare:n2];
    }];
    NSMutableArray* defaultItems=[[NSMutableArray alloc]initWithCapacity:[defaultItemsInfo count]+2];
    for (NSDictionary* info in defaultItemsInfo) {
        [defaultItems addObject:info[@"identifier"]];
    }
    _landingItemIdentifier=[defaultItems firstObject];
    [defaultItems addObject:NSToolbarFlexibleSpaceItemIdentifier];
    [defaultItems insertObject:NSToolbarFlexibleSpaceItemIdentifier atIndex:0];
    _defaultItemIdentifiers=defaultItems;
    
    
    //load window
    self.window.titleVisibility=NSWindowTitleHidden;
    //self.window.titlebarAppearsTransparent=YES;
    self.oToolbar.allowsUserCustomization=YES;
    self.oToolbar.autosavesConfiguration=YES;
    [self loadFromStorage];
}


- (void)applicationWillTerminate:(id)core
{
    [self saveToStorage];
}


- (void)loadFromStorage
{
    NSDictionary* dic=[[STCSafariStandCore si]objectForKey:kpConsolePanelToolbarConfigurationBackup];
    if(dic){
        [self.oToolbar setConfigurationFromDictionary:dic];
    }
}


- (void)saveToStorage
{
    NSDictionary* dic=[self.oToolbar configurationDictionary];
    if(dic)[[STCSafariStandCore si]setObject:dic forKey:kpConsolePanelToolbarConfigurationBackup];
    [[STCSafariStandCore si]synchronize];
}


- (NSView*)loadPanelViewForIdentifier:(NSString*)identifier
{
    NSDictionary* panelInfo=[self.consolePanelModule panelInfoForIdentifier:identifier];
    id(^loadHandler)()=panelInfo[@"loadHandler"];
    if(loadHandler){
        id viewOrCtl=loadHandler();
        if ([viewOrCtl isKindOfClass:[NSView class]]) {
            return viewOrCtl;
        }else if ([viewOrCtl isKindOfClass:[NSViewController class]]) {
            [_viewCtlPool addObject:viewOrCtl];
            return [viewOrCtl view];
        }
    }
    return nil;
}


- (void)highlighteToolbarItemIdentifier:(NSString *)itemIdentifier
{
    NSArray* items=[self.oToolbar items];
    for (NSToolbarItem* itm in items) {
        NSString* itmIdn=itm.itemIdentifier;
        if ([itmIdn length]<=0) {
            continue;
        }
        NSButton* btn=(NSButton*)[itm view];
        if ([itemIdentifier isEqualToString:itmIdn]) {
            if (btn.state != NSOnState) {
                btn.state=NSOnState;
            }
        }else{
            if (btn.state != NSOffState) {
                btn.state=NSOffState;
            }
        }
    }
}


- (void)selectTab:(NSString*)identifier
{
    NSInteger tabToSelect=NSNotFound;
    if ([identifier length]<=0) {
        if ([[[self.oTabView selectedTabViewItem]identifier]length]>0) {
            return;
        }
        identifier=_landingItemIdentifier;
        if ([identifier length]<=0) return;
    }
    
    tabToSelect=[self.oTabView indexOfTabViewItemWithIdentifier:identifier];

    if (tabToSelect!=NSNotFound) {
        [self.oTabView selectTabViewItemAtIndex:tabToSelect];
    }else{
        NSView* panelView=[self loadPanelViewForIdentifier:identifier];
        if (panelView) {
            NSTabViewItem* tabViewItem=[[NSTabViewItem alloc]initWithIdentifier:identifier];
            [tabViewItem setView:panelView];
            [tabViewItem setLabel:@""];

            [self.oTabView addTabViewItem:tabViewItem];
            [self.oTabView selectLastTabViewItem:nil];
        }
    }
    
    [self highlighteToolbarItemIdentifier:identifier];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return _defaultItemIdentifiers;
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return self.identifiers;
}


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return nil;
}


- (IBAction)actToolbarClick:(id)sender
{
    NSString* idn=[sender title];
    [self selectTab:idn];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSDictionary* panelInfo=[self.consolePanelModule panelInfoForIdentifier:itemIdentifier];
    
    NSImage* image=panelInfo[@"icon"];
    NSString* label=panelInfo[@"title"];
    
    NSToolbarItem*	result=[[NSToolbarItem alloc]initWithItemIdentifier:itemIdentifier];
    [result setToolTip:label];
    [result setImage:image];
    [result setLabel:label];
    [result setPaletteLabel:label];
    [result setAction:@selector(actToolbarClick:)];
    [result setTarget:self];

    if (flag) {
        NSButton* btn=[[NSButton alloc]initWithFrame:NSMakeRect(0, 0, 20, 20)];
        btn.target=self;
        btn.action=@selector(actToolbarClick:);
        btn.title=itemIdentifier;

        btn.imagePosition=NSImageOnly;
        btn.image=image;
        btn.bordered=NO;
        NSButtonCell* cell=btn.cell;
        cell.imageScaling=NSImageScaleProportionallyUpOrDown;
        [btn setButtonType:NSToggleButton];
        
        [result setView:btn];
    }else{
        result.minSize=NSMakeSize(20, 20);
        result.maxSize=NSMakeSize(20, 20);
    }
    return result;
}


@end


@implementation STConsolePanelWindow {
    id _bookmarksUndoController;
}

- (id)bookmarksUndoController
{
    if (!_bookmarksUndoController) {
        NSUndoManager* um=[self undoManager];
        _bookmarksUndoController=objc_msgSend([NSClassFromString(@"BookmarksUndoController") alloc], @selector(initWithUndoManager:), um);
    }
    return _bookmarksUndoController;
}

@end


@implementation STConsolePanelToolbar


- (BOOL)_allowsShowHideToolbarContextMenuItem
{
    return NO;
}


- (BOOL)_drawsBackground
{
    return NO;
}


- (BOOL)_allowsSizeMode:(NSToolbarSizeMode)arg1
{
    if (arg1==NSToolbarSizeModeSmall) {
        return YES;
    }
    return NO;
}


- (BOOL)_allowsDisplayMode:(NSToolbarDisplayMode)arg1
{
    if (arg1==NSToolbarDisplayModeIconOnly) {
        return YES;
    }
    return NO;
}

@end

