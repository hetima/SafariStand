//
//  STSidebarCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STSidebarCtl.h"
#import "STSidebarResizeHandleView.h"
#import "STVTabListCtl.h"

#import "STSafariConnect.h"

#import "DMTabBar.h"

@interface STSidebarCtl ()

@end

@implementation STSidebarCtl

+(STSidebarCtl*)viewCtl
{
    
    STSidebarCtl* result=[[STSidebarCtl alloc]initWithNibName:@"STSidebarCtl" bundle:
                                     [NSBundle bundleWithIdentifier:kSafariStandBundleID]];
    
    return result;
}

+(STSidebarCtl*)viewCtlWithCounterpartView:(NSView*)view
{
    STSidebarCtl* result=[STSidebarCtl viewCtl];
    result.counterpartView=view;
    
    return result;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    LOG(@"STSidebarCtl d");
}



-(void)awakeFromNib
{
    
    self.tabListCtl=[STVTabListCtl viewCtl];
    [self.tabListCtl setupWithTabView:nil];
    //setup tabview
    [self.oPrimaryTabView setTabViewType:NSNoTabsLineBorder];
    //[self.oPrimaryTabView setDelegate:nil];
    
    NSTabViewItem* tabListItem=[[NSTabViewItem alloc]initWithIdentifier:@"tablist"];
    [tabListItem setView:self.tabListCtl.view];
    [self.oPrimaryTabView addTabViewItem:tabListItem];
    [self.oPrimaryTabView selectTabViewItem:tabListItem];
    
    [self.oSecondaryTabView setTabViewType:NSNoTabsNoBorder];
    //[self.oSecondaryTabView setDelegate:nil];

    
    //setup tabbar
    DMTabBarItem* itm=[DMTabBarItem tabBarItemWithIcon:STSafariBundleImageNamed(@"ToolbarBookmarksTemplate") tag:1];
    NSArray* itms=@[itm];
    self.oPrimaryTabbar.tabBarItems=itms;
    
    [self.oPrimaryTabbar handleTabBarItemSelection:^(DMTabBarItemSelectionType selectionType, DMTabBarItem *targetTabBarItem, NSUInteger targetTabBarItemIndex) {
        if (selectionType == DMTabBarItemSelectionType_WillSelect) {
            //NSLog(@"Will select %lu/%@",targetTabBarItemIndex,targetTabBarItem);
        } else if (selectionType == DMTabBarItemSelectionType_DidSelect) {
            //NSLog(@"Did select %lu/%@",targetTabBarItemIndex,targetTabBarItem);
        }
    }];
    
    [self.oSecondaryTabbar handleTabBarItemSelection:^(DMTabBarItemSelectionType selectionType, DMTabBarItem *targetTabBarItem, NSUInteger targetTabBarItemIndex) {
        if (selectionType == DMTabBarItemSelectionType_WillSelect) {
            //NSLog(@"Will select %lu/%@",targetTabBarItemIndex,targetTabBarItem);
        } else if (selectionType == DMTabBarItemSelectionType_DidSelect) {
            //NSLog(@"Did select %lu/%@",targetTabBarItemIndex,targetTabBarItem);
        }
    }];

    
}



- (BOOL)rightSide
{
    return  [(STSidebarFrameView*)self.view rightSide];
}

- (void)setRightSide:(BOOL)rightSide
{
    
    [(STSidebarFrameView*)self.view setRightSide:rightSide];
    
    NSRect counterpartFrame=self.counterpartView.frame;
    NSRect sidebarFrame=self.view.frame;
    NSRect unionRect=NSUnionRect(counterpartFrame, sidebarFrame);
    
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
    
    if (rightSide) {
        sidebarFrame.origin.x+=counterpartFrame.size.width;
    }else{
        counterpartFrame.origin.x+=sidebarFrame.size.width;
    }

}

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


#pragma mark - NSSplitView delegate


- (void)splitViewDidResizeSubviews:(NSNotification *)notification;
{

}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{

    return YES;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return YES;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
#define kSplitViewBottomMinHeight 25
    if (proposedMin<kSplitViewBottomMinHeight) {
        return kSplitViewBottomMinHeight;
    }

    return proposedMin;

}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
#define kSplitViewBottomMinHeight 25
    LOG(@"proposedMax %lu,%2f", dividerIndex, proposedMax);

    
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

- (void)drawRect:(NSRect)dirtyRect
{
//    [[NSColor darkGrayColor]set];
//    NSFrameRectWithWidth([self bounds], 1.0);
}


- (void)dealloc
{
    LOG(@"STSidebarFrameView d");
}

@end