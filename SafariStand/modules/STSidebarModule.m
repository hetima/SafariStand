//
//  STSidebarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import "STSidebarModule.h"
#import "STSidebarCtl.h"
#import "STSToolbarModule.h"

@implementation STSidebarModule

//NSTabView - (NSRect)contentRect
static NSRect (*orig_NSTabViewContentRect)(id, SEL);
static NSRect ST_NSTabViewContentRect(id self, SEL sel)
{
    
    NSArray* subviews=[self subviews];
    for (NSView* subview in subviews) {
        if ([subview isKindOfClass:[STSidebarFrameView class]]) {
            NSRect origRect=orig_NSTabViewContentRect(self, sel);
            NSRect sidebarRect=[subview frame];
            BOOL rightside=[(STSidebarFrameView*)subview rightSide];
            
            origRect.size.width-=sidebarRect.size.width;
            if (!rightside) {
                origRect.origin.x+=sidebarRect.size.width;
            }
            return origRect;
        }
    }
    
    return orig_NSTabViewContentRect(self, sel);
}


//kpSidebarShowsDefault
static void (*orig_showWindow)(id, SEL, id);
static void ST_showWindow(id self, SEL _cmd, id sender)
{
    orig_showWindow(self, _cmd, sender);
    if ( ![[NSUserDefaults standardUserDefaults]boolForKey:kpSidebarShowsDefault] ||
        [self htaoValueForKey:kAOValueNotShowSidebarAuto] ) {
        return;
    }
    
    [self htaoSetValue:@YES forKey:kAOValueNotShowSidebarAuto];
    NSSize winSize=[[self window]frame].size;
    if(winSize.width>640 && winSize.height>600){
        [[STCSafariStandCore mi:@"STSidebarModule"]installSidebarToWindow:[self window]];
    }
    
    
}


- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        orig_NSTabViewContentRect = (NSRect (*)(id, SEL))RMF(NSClassFromString(@"NSTabView"),
                                                   @selector(contentRect), ST_NSTabViewContentRect);

        //kpSidebarShowsDefault
        orig_showWindow = (void (*)(id, SEL, id))RMF(NSClassFromString(kSafariBrowserWindowController),  @selector(showWindow:), ST_showWindow);


        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Sidebar" action:@selector(toggleSidebar:) keyEquivalent:@""];
        [itm setTarget:self];
        [core addItemToStandMenu:itm];
        
        itm=[[NSMenuItem alloc]initWithTitle:@"SidebarLR" action:@selector(toggleSidebarLR:) keyEquivalent:@""];
        [itm setTarget:self];
        [core addItemToStandMenu:itm];

        [core registerToolbarIdentifier:STSidebarTBItemIdentifier module:self];

    }
    return self;
}

- (void)dealloc
{

}

- (void)modulesDidFinishLoading:(id)core
{
    [self showSidebarForExistingWindow];
}

- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* result=nil;
    if ([itemIdentifier isEqualToString:STSidebarTBItemIdentifier]) {
        static NSImage* STTBToggleSidebarIcon=nil;
        if (!STTBToggleSidebarIcon) {
            NSString* imgPath=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]pathForImageResource:@"STTBToggleSidebar"];
            STTBToggleSidebarIcon=[[NSImage alloc]initWithContentsOfFile:imgPath];
            [STTBToggleSidebarIcon setTemplate:YES];
        }
        result=[(STSToolbarModule*)[STCSafariStandCore mi:@"STSToolbarModule"]simpleToolBarItem:STSidebarTBItemIdentifier
                label:@"Stand:Toggle Sidebar" action:@selector(STToggleSidebar:) iconImage:STTBToggleSidebarIcon];

    }
    return result;
}


//起動時作成済みのウインドウにサイドバー表示
-(void)showSidebarForExistingWindow
{

    if (![[NSUserDefaults standardUserDefaults]boolForKey:kpSidebarShowsDefault]) {
        return;
    }
    
    //check exists window
    NSArray *windows=[NSApp windows];
    for (NSWindow* win in windows) {
        id winCtl=[win windowController];
        if([win isVisible] && [[winCtl className]isEqualToString:kSafariBrowserWindowController]){
            //install
            [self installSidebarToWindow:win];
        }
    }
}



-(void)toggleSidebar:(id)sender
{
    NSWindow* win=STSafariCurrentBrowserWindow();
    //STSidebarContentView* view=[self sidebarContentViewForWindow:win];
    
    STSidebarCtl* ctl=[self sidebarCtlForWindow:win];

    if (ctl) {
        [self removeSidebar:ctl fromWindow:win];
    }else{
        [self installSidebarToWindow:win];
    }
}

-(void)toggleSidebarLR:(id)sender
{
    NSWindow* win=STSafariCurrentBrowserWindow();
    //STSidebarContentView* view=[self sidebarContentViewForWindow:win];
    
    STSidebarCtl* ctl=[self sidebarCtlForWindow:win];
    
    if (ctl) {
        BOOL rightSide=![ctl rightSide];
        [[NSUserDefaults standardUserDefaults]setBool:rightSide forKey:kpSidebarIsRightSide];
        [ctl setRightSide:rightSide];
    }
}

-(void)installSidebarToWindow:(NSWindow*)win
{
    NSTabView* tabView=STSafariTabViewForWindow(win);

    if ([self sidebarCtlForWindow:win] || !tabView) {
        return;
    }
    BOOL rightSide=[[NSUserDefaults standardUserDefaults]boolForKey:kpSidebarIsRightSide];
    CGFloat width=[[NSUserDefaults standardUserDefaults]floatForKey:kpSidebarWidth];
    if (width<kSidebarFrameMinWidth) {
        width=kSidebarFrameMinWidth;
    }
    CGFloat influence=(win.frame.size.width)/2;
    if (width>influence) {
        width=influence;
    }

    
    STSidebarCtl* ctl=[STSidebarCtl viewCtl];
    [ctl installToTabView:tabView sidebarWidth:width rightSide:rightSide];

    [win htaoSetValue:ctl forKey:@"sidebarCtl"];

}

-(void)removeSidebar:(STSidebarCtl*)ctl fromWindow:(NSWindow*)win
{
    [ctl uninstallFromTabView];
    
    [win htaoSetValue:nil forKey:@"sidebarCtl"];
}



-(STSidebarCtl*)sidebarCtlForWindow:(NSWindow*)win
{
    STSidebarCtl* ctl=[win htaoValueForKey:@"sidebarCtl"];
    return ctl;
}

-(STSidebarFrameView*)sidebarContentViewForWindow:(NSWindow*)win
{
    NSView* tabView=STSafariTabViewForWindow(win);
    return [self sidebarContentViewForTabView:tabView];
}

-(STSidebarFrameView*)sidebarContentViewForTabView:(NSView*)tabView
{
    NSArray* subviews=[tabView subviews];
    for (NSView* subview in subviews) {
        if ([subview isKindOfClass:[STSidebarFrameView class]]) {
            return (STSidebarFrameView*)subview;
        }
    }
    return nil;
}



@end


