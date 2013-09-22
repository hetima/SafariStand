//
//  STSidebarModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import "STSidebarModule.h"


//NSTabView - (NSRect)contentRect
static NSRect (*orig_NSTabViewContentRect)(id, SEL);
static NSRect ST_NSTabViewContentRect(id self, SEL sel)
{
    
    NSArray* subviews=[self subviews];
    for (NSView* subview in subviews) {
        if ([subview isKindOfClass:[STSidebarContentView class]]) {
            NSRect origRect=orig_NSTabViewContentRect(self, sel);
            NSRect sidebarRect=[subview frame];
            BOOL rightside=[(STSidebarContentView*)subview rightSide];
            
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

-(void)toggleSidebar:(id)sender
{
    NSWindow* win=STSafariCurrentBrowserWindow();
    STSidebarContentView* view=[self sidebarContentViewForWindow:win];

    if (view) {
        [self removeSidebar:view fromWindow:win];
    }else{
        [self installSidebarToWindow:win];
    }
    
}

-(void)installSidebarToWindow:(NSWindow*)win
{
    NSView* tabContentView=[self tabContentViewForTabView:STTabViewForWindow(win)];

    if (!tabContentView) {
        return;
    }
    BOOL rightSide=YES;
    CGFloat width=400;
    
    NSRect tabViewFrame=[tabContentView frame];
    NSRect sidebarFrame=tabViewFrame;
    NSUInteger autoresizingMask;
    if (tabViewFrame.size.width<width) {
        width=tabViewFrame.size.width/2;
    }
    tabViewFrame.size.width-=width;
    sidebarFrame.size.width=width;
    if (rightSide) {
        sidebarFrame.origin.x+=tabViewFrame.size.width;
        autoresizingMask=NSViewHeightSizable + NSViewMinXMargin;
    }else{
        tabViewFrame.origin.x+=sidebarFrame.size.width;
        autoresizingMask=NSViewHeightSizable + NSViewMaxXMargin;
    }
    STSidebarContentView* sidebarView=[[STSidebarContentView alloc]initWithFrame:sidebarFrame];
    sidebarView.rightSide=rightSide;
    [sidebarView setAutoresizingMask:autoresizingMask];
    [[tabContentView superview]addSubview:sidebarView];
    [sidebarView setFrame:sidebarFrame];
    [tabContentView setFrame:tabViewFrame];
}

-(void)removeSidebar:(STSidebarContentView*)sidebarView fromWindow:(NSWindow*)win
{
    NSView* tabContentView=[self tabContentViewForTabView:STTabViewForWindow(win)];
    if (!tabContentView) {
        return;
    }
    
    if ([tabContentView superview]!=[sidebarView superview]) {
        [sidebarView removeFromSuperview];
        return;
    }
    
    NSRect tabViewFrame=[tabContentView frame];
    NSRect sidebarFrame=[sidebarView frame];
    NSRect unionRect=NSUnionRect(tabViewFrame, sidebarFrame);
    [tabContentView setFrame:unionRect];
    [sidebarView removeFromSuperview];
}

-(STSidebarContentView*)sidebarContentViewForWindow:(NSWindow*)win
{
    NSView* tabView=STTabViewForWindow(win);
    return [self sidebarContentViewForTabView:tabView];
}

-(STSidebarContentView*)sidebarContentViewForTabView:(NSView*)tabView
{
    NSArray* subviews=[tabView subviews];
    for (NSView* subview in subviews) {
        if ([subview isKindOfClass:[STSidebarContentView class]]) {
            return (STSidebarContentView*)subview;
        }
    }
    return nil;
}

-(NSView*)tabContentViewForTabView:(NSView*)tabView
{
    NSArray* subviews=[tabView subviews];
    for (NSView* subview in subviews) {
        if ([[subview className]isEqualToString:@"TabContentView"]) {
            return subview;
        }
    }
    return nil;
}


@end


@implementation STSidebarContentView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSFrameRectWithWidth([self bounds], 8.0);
}


- (void)dealloc
{
    LOG(@"STSidebarContentView d");
}

@end