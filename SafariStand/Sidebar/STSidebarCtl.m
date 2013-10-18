//
//  STSidebarCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STSidebarCtl.h"
#import "STTabProxy.h"
#import "STSidebarResizeHandleView.h"
#import "STVTabListCtl.h"

#import "STSafariConnect.h"
#import "NSObject+HTAssociatedObject.h"

#import "DMTabBar.h"

@interface STSidebarCtl ()

@end

#define kTabListTag 1
#define kTabListIdentifier @"tablist"


@implementation STSidebarCtl

+(STSidebarCtl*)viewCtl
{
    
    STSidebarCtl* result=[[STSidebarCtl alloc]initWithNibName:@"STSidebarCtl" bundle:
                                     [NSBundle bundleWithIdentifier:kSafariStandBundleID]];
    
    return result;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.targetView=nil;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewReplaced:) name:STTabViewDidReplaceNote object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    LOG(@"STSidebarCtl d");
}

- (void)installToTabView:(NSTabView*)tabView sidebarWidth:(CGFloat)width rightSide:(BOOL)rightSide
{
    if (self.targetView) {
        [self uninstallFromTabView];
    }
    
    self.targetView=tabView;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewItemSelected:) name:STTabViewDidSelectItemNote object:self.targetView];
    
    
    //sidebar の frame を仮セット
    NSRect sidebarFrame=[tabView frame];
    sidebarFrame.size.width=width;
    
    [self.view setFrame:sidebarFrame];
    [tabView addSubview:self.view];
    
    //layout
    [self layout:rightSide];
     
}

- (void)uninstallFromTabView
{
    if (!self.targetView) {
        return;
    }
    
    [self.tabListCtl uninstallFromTabView];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:STTabViewDidSelectItemNote object:self.targetView];
    [self.view removeFromSuperview];
    
    //TabContentView を修正
    NSRect counterpartFrame=NSMakeRect(0, 0, NSWidth(self.targetView.frame), NSHeight(self.targetView.frame));
    [self.counterpartView setFrame:counterpartFrame];
    
    self.targetView=nil;
}

- (void)tabViewReplaced:(NSNotification*)note
{
    //古い tabView は既に window から取り除かれているので self.view.window==nil
    NSTabView* tabView=[note object];
    STSidebarCtl* ctl=[tabView.window htaoValueForKey:@"sidebarCtl"];
    if (self==ctl) {
        [self installToTabView:tabView sidebarWidth:NSWidth(self.view.frame) rightSide:[self rightSide]];
    }
}

- (void)tabViewItemSelected:(NSNotification*)note
{
    [self layout:[self rightSide]];
}


-(void)awakeFromNib
{
    
    self.tabListCtl=[STVTabListCtl viewCtl];
    [self.tabListCtl setupWithTabView:self.targetView];
    //setup tabview
    [self.oPrimaryTabView setTabViewType:NSNoTabsNoBorder];
    //[self.oPrimaryTabView setDelegate:nil];
    
    NSTabViewItem* tabListItem=[[NSTabViewItem alloc]initWithIdentifier:kTabListIdentifier];
    [tabListItem setView:self.tabListCtl.view];
    [self.oPrimaryTabView addTabViewItem:tabListItem];
    [self.oPrimaryTabView selectTabViewItem:tabListItem];
    
    [self.oSecondaryTabView setTabViewType:NSNoTabsNoBorder];
    //[self.oSecondaryTabView setDelegate:nil];

    
    //setup tabbar
    self.oPrimaryTabbar.tabBarItems=({
        DMTabBarItem* itm=[DMTabBarItem tabBarItemWithIcon:[NSImage imageNamed:@"NSIconViewTemplate"] tag:kTabListTag];
        @[itm];
    });

    //DMTabBar の Block にキャプチャされると循環参照するので __weak
    STSidebarCtl* __weak weakSelf=self;
    
    [self.oPrimaryTabbar handleTabBarItemSelection:^(DMTabBarItemSelectionType selectionType, DMTabBarItem *targetTabBarItem, NSUInteger targetTabBarItemIndex) {
        if (selectionType == DMTabBarItemSelectionType_WillSelect) {

        } else if (selectionType == DMTabBarItemSelectionType_DidSelect) {
            if (targetTabBarItem.tag==kTabListTag) {
                [weakSelf.oPrimaryTabView selectTabViewItemWithIdentifier:kTabListIdentifier];
            }
        }
    }];
    
    [self.oSecondaryTabbar handleTabBarItemSelection:^(DMTabBarItemSelectionType selectionType, DMTabBarItem *targetTabBarItem, NSUInteger targetTabBarItemIndex) {
        if (selectionType == DMTabBarItemSelectionType_WillSelect) {

        } else if (selectionType == DMTabBarItemSelectionType_DidSelect) {

        }
    }];

    
}



- (BOOL)rightSide
{
    return  [(STSidebarFrameView*)self.view rightSide];
}

- (void)setRightSide:(BOOL)rightSide
{
    BOOL currentSide=[(STSidebarFrameView*)self.view rightSide];
    if (currentSide != rightSide) {
        [self layout:rightSide];
    }
}


- (void)layout:(BOOL)rightSide
{
    NSView* counterpartView=STSafariTabContentViewForTabView(self.targetView);
    if (!counterpartView) {
        NSLog(@"Error: TabContentView not found.");
        return;
    }
    self.counterpartView=counterpartView;
    
    [(STSidebarFrameView*)self.view setRightSide:rightSide];
    
    NSRect counterpartFrame=NSMakeRect(0, 0, NSWidth(self.targetView.frame), NSHeight(self.targetView.frame));
    NSRect sidebarFrame=NSMakeRect(0, 0, NSWidth(self.view.frame), NSHeight(self.targetView.frame));
    NSRect unionRect=counterpartFrame;
    
    counterpartFrame.size.width=NSWidth(unionRect)-NSWidth(sidebarFrame);
    

    NSRect resizeHandleFrame=self.oResizeHandle.frame;
    NSUInteger resizeHandleAutoresizingMask, sidebarFrameAutoresizingMask;
    if (rightSide) {
        resizeHandleFrame.origin.x=0;
        resizeHandleAutoresizingMask=NSViewMaxXMargin;

        sidebarFrameAutoresizingMask=NSViewHeightSizable + NSViewMinXMargin;
        counterpartFrame.origin.x=NSMinX(unionRect);
        sidebarFrame.origin.x=NSMaxX(counterpartFrame);
    }else{
        CGFloat x=self.oResizeHandle.superview.frame.size.width;
        resizeHandleFrame.origin.x=x-resizeHandleFrame.size.width;
        resizeHandleAutoresizingMask=NSViewMinXMargin;
        
        sidebarFrameAutoresizingMask=NSViewHeightSizable + NSViewMaxXMargin;
        sidebarFrame.origin.x=NSMinX(unionRect);
        counterpartFrame.origin.x=NSMaxX(sidebarFrame);
    }
    
    [self.counterpartView setFrame:counterpartFrame];
    [self.view setFrame:sidebarFrame];
    [self.view setAutoresizingMask:sidebarFrameAutoresizingMask];
    [self.oResizeHandle setFrame:resizeHandleFrame];
    [self.oResizeHandle setAutoresizingMask:resizeHandleAutoresizingMask];
    
    NSRect splitViewFrame=self.oSplitView.frame;
    splitViewFrame.size.width=NSWidth(self.view.frame)-1;
    if (rightSide) {
        splitViewFrame.origin.x=1;
    }else{
        splitViewFrame.origin.x=0;
    }
    [self.oSplitView setFrame:splitViewFrame];

}

#pragma mark - NSSplitView

- (CGFloat)counterpartResizeLimit
{
    CGFloat width=[self.counterpartView frame].size.width - kCounterpartMinWidth;
    
    return width>=0 ? width:0;
}

- (CGFloat)sidebarFrameResizeLimit
{
    CGFloat width=[self.view frame].size.width - kSidebarFrameMinWidth;
    
    return width>=1 ? width:0;
    
}

- (STMinMax)userDragResizeLimit
{
    STMinMax result;
    CGFloat sidebarFrameResizeLimit=self.sidebarFrameResizeLimit;
    CGFloat counterpartResizeLimit=self.counterpartResizeLimit;
    if ([(STSidebarFrameView*)self.view rightSide]) {
        result.max=sidebarFrameResizeLimit;
        result.min=0-counterpartResizeLimit;
    }else{
        result.max=counterpartResizeLimit;
        result.min=0-sidebarFrameResizeLimit;
    }
    return result;
}

- (void)sidebarResizeHandleWillStartTracking:(STSidebarResizeHandleView*)resizeHandle
{
    if ([(STSidebarFrameView*)self.view rightSide]) {
        resizeHandle.rightView=self.view;
        resizeHandle.leftView=self.counterpartView;
    }else{
        resizeHandle.rightView=self.counterpartView;
        resizeHandle.leftView=self.view;
    }
    resizeHandle.resizeLimit=[self userDragResizeLimit];
}

- (void)sidebarResizeHandleDidEndTracking:(STSidebarResizeHandleView*)resizeHandle
{
    
}


- (void)splitViewDidResizeSubviews:(NSNotification *)notification;
{

}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{

    return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return NO;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
#define kSplitViewTopMinHeight 25

    if (proposedMin<kSplitViewTopMinHeight) {
        return kSplitViewTopMinHeight;
    }

    return proposedMin;

}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
#define kSplitViewBottomMinHeight 24

    return proposedMax-kSplitViewBottomMinHeight;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
    //LOG(@"%lu,%2f", dividerIndex, proposedPosition);
    //snap to SouceList min width
    /*if (dividerIndex==0){
     
     if(proposedPosition<=SouceViewMinWidth*2) {
     if (proposedPosition>SouceViewMinWidth*1.6) {
     return SouceViewMinWidth*2;
     }
     return SouceViewMinWidth;
     }
     }*/
    return proposedPosition;
}


#pragma mark -

@end


@implementation STSidebarFrameView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        
    }
    return self;
}


- (void)dealloc
{
    LOG(@"STSidebarFrameView d");
}

@end