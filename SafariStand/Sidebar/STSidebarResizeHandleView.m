//
//  STSidebarResizeHandleView.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STSidebarResizeHandleView.h"

@implementation STSidebarResizeHandleView
{
    NSPoint _trackingStartPoint;
	BOOL	_tracking;
    NSRect _beginningLeftFrame;
    NSRect _beginningRightFrame;
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    
    return self;
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect
{
#define kLineSpace 4
#define kLinePadding 5
    static NSColor * lightColor=nil;
    static NSColor * darkColor=nil;
    if (lightColor==nil) {
        lightColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
    }
    if (darkColor==nil) {
        darkColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
    }
    
    NSRect rect=[self bounds];
    rect.origin.y+=kLinePadding;
    rect.size.height-=kLinePadding*2;
    rect.size.width=1;
    rect.origin.x+=kLinePadding;
    
    [lightColor set];
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;
    
    rect.origin.x-=kLineSpace*4+1;
    [darkColor set];
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;
    NSRectFill(rect);
    rect.origin.x+=kLineSpace;

}


- (void)mouseDown:(NSEvent *)theEvent
{
    [self.delegate sidebarResizeHandleWillStartTracking:self];
    _trackingStartPoint=[theEvent locationInWindow];

	if(self.leftView && self.rightView){
        _beginningLeftFrame=self.leftView.frame;
        _beginningRightFrame=self.rightView.frame;
		_tracking=YES;
	}else{
		_tracking=NO;
	}
}

- (void)mouseUp:(NSEvent *)theEvent;
{
	if(_tracking){
        if ([self.delegate respondsToSelector:@selector(sidebarResizeHandleDidEndTracking:)]) {
            [self.delegate sidebarResizeHandleDidEndTracking:self];
        }
	}
	_tracking=NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    
	if(!_tracking)return;
    
    NSPoint currentPoint=[theEvent locationInWindow];
    //float   dy=currentPoint.y-_trackingStartPoint.y;
    float   dx=floor(currentPoint.x-_trackingStartPoint.x);
    
    if (dx<self.resizeLimit.min || dx>self.resizeLimit.max) {
        return;
    }
    
    NSRect leftFrame=self.leftView.frame;
    NSRect rightFrame=self.rightView.frame;
    
    leftFrame.size.width=NSWidth(_beginningLeftFrame)+dx;
    rightFrame.size.width=NSWidth(_beginningRightFrame)-dx;
    rightFrame.origin.x=NSMinX(_beginningRightFrame)+dx;
    
    [self.leftView setFrame:leftFrame];
    [self.rightView setFrame:rightFrame];

}



@end
