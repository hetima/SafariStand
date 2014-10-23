//
//  STConsolePanelModule.m
//  SafariStand


#import "SafariStand.h"
#import "STConsolePanelModule.h"


@implementation STConsolePanelModule {
    
    STConsolePanelCtl* _winCtl;
}


-(id)initWithStand:(STCSafariStandCore*)core
{
    self = [super initWithStand:core];
    if (self) {
        //[self observePrefValue:];
        _winCtl=nil;
        
        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Console Panel" action:@selector(actShowConsolePanel:) keyEquivalent:@"k"];
        [itm setKeyEquivalentModifierMask:NSCommandKeyMask|NSAlternateKeyMask];
        [itm setTarget:self];
        [itm setTag:kMenuItemTagConsolePanel];
        [core addItemToStandMenu:itm];
    }
    return self;
}


- (void)dealloc
{

}


- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}


- (IBAction)actShowConsolePanel:(id)sender
{
    [self showConsolePanelAndSelectTab:nil];
}



- (void)showConsolePanelAndSelectTab:(NSString*)identifier
{
    if(!_winCtl){
        _winCtl=[[STConsolePanelCtl alloc]initWithWindowNibName:@"STConsolePanel"];
        [_winCtl commonConsolePanelCtlInit];
        [[STCSafariStandCore si]sendMessage:@selector(stMessageConsolePanelLoaded:) toAllModule:self];
    }
    NSInteger tabToSelect=NSNotFound;
    if ([identifier length]>0) {
        tabToSelect=[_winCtl.oTabView indexOfTabViewItemWithIdentifier:identifier];
    }

    if (tabToSelect!=NSNotFound) {
        [_winCtl.oTabView selectTabViewItemAtIndex:tabToSelect];
    }else{
        identifier=[[_winCtl.oTabView selectedTabViewItem]identifier];
        
        if ([identifier length]<=0){
            [_winCtl.oTabView selectFirstTabViewItem:nil];
            identifier=[[_winCtl.oTabView selectedTabViewItem]identifier];
        }

    }
    
    [_winCtl highlighteToolbarItemIdentifier:identifier];
    
    [_winCtl showWindow:self];
    
}


- (void)addViewController:(NSViewController*)viewCtl withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight
{
    [_winCtl addViewController:viewCtl withIdentifier:identifier title:title icon:icon  weight:(NSInteger)weight];
}


- (void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight
{
    [_winCtl addPane:view withIdentifier:identifier title:title icon:icon  weight:weight];
}


@end


@implementation STConsolePanelCtl{
    NSMutableArray* _viewCtlPool;
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
    }
    return self;
}


- (void)commonConsolePanelCtlInit
{
    _viewCtlPool=[[NSMutableArray alloc]initWithCapacity:8];
    self.window.titleVisibility=NSWindowTitleHidden;
    self.window.titlebarAppearsTransparent=YES;
    
    [self addSafariBookmarksView];

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


- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return nil;
}


- (IBAction)actToolbarClick:(id)sender
{
    NSString* idn=[sender title];
    [self.oTabView selectTabViewItemWithIdentifier:idn];
    [self highlighteToolbarItemIdentifier:idn];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* item=[super toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (flag) {
        NSButton* btn=[[NSButton alloc]initWithFrame:NSMakeRect(0, 0, 20, 20)];
        btn.target=self;
        btn.action=@selector(actToolbarClick:);
        btn.title=itemIdentifier;

        btn.imagePosition=NSImageOnly;
        btn.image=item.image;
        btn.bordered=NO;
        NSButtonCell* cell=btn.cell;
        cell.imageScaling=NSImageScaleProportionallyUpOrDown;
        [btn setButtonType:NSToggleButton];
        
        [item setView:btn];
    }
    return item;
}

- (void)addViewController:(NSViewController*)viewCtl withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight
{
    [_viewCtlPool addObject:viewCtl];
    NSView *view=viewCtl.view;
    [self addPane:view withIdentifier:identifier title:title icon:icon  weight:(NSInteger)weight];
}


- (void)addPane:(NSView*)view withIdentifier:(NSString*)identifier title:(NSString*)title icon:(NSImage*)icon weight:(NSInteger)weight
{
    [self window];
    [self addIdentifier:identifier];
    NSTabView* tabView=[self oTabView];
    NSToolbar* toolbar=[self oToolbar];
    
    NSTabViewItem* tabViewItem=[[NSTabViewItem alloc]initWithIdentifier:identifier];
    [tabViewItem setView:view];
    [tabViewItem setLabel:title];
    if(icon)[tabViewItem htao_setValue:icon forKey:@"image"];
    [tabView addTabViewItem:tabViewItem];
    
    NSArray* items=[toolbar items];
    NSInteger toolbaritemCount=[items count];
    NSInteger atIndex=-1;
    if (toolbaritemCount<=2) {
        atIndex=toolbaritemCount-1;
    }else{
        NSInteger i=1;
        for (i=1; i<toolbaritemCount-1; i++) {
            NSToolbarItem* itm=[items objectAtIndex:i];
            NSInteger tag=itm.tag;
            if (tag>weight) {
                atIndex=i;
                break;
            }
        }
        atIndex=i;
    }
    
    if (atIndex<0) {
        atIndex=0;
    }
    
    [toolbar insertItemWithItemIdentifier:identifier atIndex:atIndex];
    
    NSToolbarItem* insertedItem=[[toolbar items]objectAtIndex:atIndex];
    insertedItem.tag=weight;
    
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
    id bookmarksViewController=objc_msgSend([NSClassFromString(@"BookmarksSidebarViewController") alloc], @selector(initWithNibName:bundle:), nil, nil);
    [bookmarksViewController view];
    NSImage* img=STSafariBundleImageNamed(@"SB_ModernTabIconBookmarks");
    [img setTemplate:YES];
    [self addViewController:bookmarksViewController withIdentifier:@"Bookmarks" title:@"Bookmarks" icon:img weight:1];
    
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
            NSURL* url=[STConsolePanelCtl selectedURLOnSafariBookmarksView:slf];
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
            NSURL* url=[STConsolePanelCtl selectedURLOnSafariBookmarksView:slf];
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
            NSURL* url=[STConsolePanelCtl selectedURLOnSafariBookmarksView:slf];
            if(url)STSafariGoToURLWithPolicy(url, poNewWindow);
        }else{
            call.as_void(slf, sel, obj);
        }
        
    }_WITHBLOCK;

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
