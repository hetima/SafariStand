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



- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "NSTabView", "contentRect",
         KZRMethodInspection, call, sel,
         ^NSRect(id slf)
        {
            NSArray* subviews=[slf subviews];
            for (NSView* subview in subviews) {
                if ([subview isKindOfClass:[STSidebarFrameView class]]) {
                    NSRect origRect=call.as_rect(slf, sel);
                    NSRect sidebarRect=[subview frame];
                    BOOL rightside=[(STSidebarFrameView*)subview rightSide];
                    
                    origRect.size.width-=sidebarRect.size.width;
                    if (!rightside) {
                        origRect.origin.x+=sidebarRect.size.width;
                    }
                    return origRect;
                }
            }
            
            return call.as_rect(slf, sel);
         });

        //kpSidebarShowsDefault
        
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         kSafariBrowserWindowControllerCstr, "showWindow:",
         KZRMethodInspection, call, sel,
         ^(id slf, id sender)
        {
            call.as_void(slf, sel, sender);
            if ( ![[NSUserDefaults standardUserDefaults]boolForKey:kpSidebarShowsDefault] ||
                [slf htao_valueForKey:kAOValueNotShowSidebarAuto] ) {
                return;
            }
            
            [slf htao_setValue:@YES forKey:kAOValueNotShowSidebarAuto];
            NSSize winSize=[[slf window]frame].size;
            if(winSize.width>640 && winSize.height>600){
                [self installSidebarToWindow:[slf window]];
            }
         });


        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Sidebar" action:@selector(toggleSidebar:) keyEquivalent:@""];
        [itm setTarget:self];
        [core addItemToStandMenu:itm];
/*
        itm=[[NSMenuItem alloc]initWithTitle:@"SidebarLR" action:@selector(toggleSidebarLR:) keyEquivalent:@""];
        [itm setTarget:self];
        [core addItemToStandMenu:itm];
*/
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

    [win htao_setValue:ctl forKey:@"sidebarCtl"];

}

-(void)removeSidebar:(STSidebarCtl*)ctl fromWindow:(NSWindow*)win
{
    [ctl uninstallFromTabView];
    
    [win htao_setValue:nil forKey:@"sidebarCtl"];
}



-(STSidebarCtl*)sidebarCtlForWindow:(NSWindow*)win
{
    STSidebarCtl* ctl=[win htao_valueForKey:@"sidebarCtl"];
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


