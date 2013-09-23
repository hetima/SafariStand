//
//  STSidebarCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STSidebarCtl.h"
#import "STSidebarResizeHandleView.h"

@interface STSidebarCtl ()

@end

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
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    LOG(@"STSidebarCtl d");
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
    NSFrameRectWithWidth([self bounds], 8.0);
}


- (void)dealloc
{
    LOG(@"STSidebarFrameView d");
}

@end