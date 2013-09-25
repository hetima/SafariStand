//
//  STSidebarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import "STSidebarModule.h"
#import "STSidebarCtl.h"


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


@implementation STSidebarModule

- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        orig_NSTabViewContentRect = (NSRect (*)(id, SEL))RMF(NSClassFromString(@"NSTabView"),
                                                   @selector(contentRect), ST_NSTabViewContentRect);

        
        //[self observePrefValue:];

        NSMenuItem* itm=[[NSMenuItem alloc]initWithTitle:@"Sidebar" action:@selector(toggleSidebar:) keyEquivalent:@""];
        [itm setTarget:self];
        [core addItemToStandMenu:itm];
        
        itm=[[NSMenuItem alloc]initWithTitle:@"SidebarLR" action:@selector(toggleSidebarLR:) keyEquivalent:@""];
        [itm setTarget:self];
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


//起動時作成済みのウインドウにサイドバー表示
-(void)showSidebarForExistingWindow
{
    if (![[NSUserDefaults standardUserDefaults]boolForKey:kpSidebarEnabled]) {
        return;
    }
    
    if (![[NSUserDefaults standardUserDefaults]boolForKey:kpSidebarShowsDefault]) {
        return;
    }
    
    //check exists window
    NSArray *windows=[NSApp windows];
    for (NSWindow* win in windows) {
        id winCtl=[win windowController];
        if([win isVisible] && [[winCtl className]isEqualToString:kSafariBrowserWindowController]){
            //install

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
        [ctl setRightSide:![ctl rightSide]];
    }
}

-(void)installSidebarToWindow:(NSWindow*)win
{
    NSTabView* tabView=STTabViewForWindow(win);

    if (!tabView) {
        return;
    }
    BOOL rightSide=YES;
    CGFloat width=kSidebarFrameMinWidth;
    
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
    NSView* tabView=STTabViewForWindow(win);
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


