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
    NSFrameRectWithWidth([self bounds], 1.0);
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
    
    leftFrame.size.width=_beginningLeftFrame.size.width+dx;
    rightFrame.size.width=_beginningRightFrame.size.width-dx;
    rightFrame.origin.x=_beginningRightFrame.origin.x+dx;
    
    [self.leftView setFrame:leftFrame];
    [self.rightView setFrame:rightFrame];

}



@end
