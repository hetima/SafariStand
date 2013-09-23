//
//  STSidebarCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@interface STSidebarCtl : NSViewController

+ (STSidebarCtl*)viewCtl;

@end


@interface STSidebarFrameView : NSView

@property (nonatomic,assign)BOOL rightSide;

@end
