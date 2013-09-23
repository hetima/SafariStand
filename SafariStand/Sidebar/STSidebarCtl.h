//
//  STSidebarCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

#define kCounterpartMinWidth 100
#define kSidebarFrameMinWidth 200

@class DMTabBar, STSidebarResizeHandleView;

@interface STSidebarCtl : NSViewController

@property (weak) IBOutlet DMTabBar *oTabbar;
@property (weak) IBOutlet STSidebarResizeHandleView *oResizeHandle;

@property (nonatomic,assign)NSView* counterpartView;

+ (STSidebarCtl*)viewCtl;

- (BOOL)rightSide;
- (void)setRightSide:(BOOL)rightSide;

- (CGFloat)counterpartResizeLimit;
- (CGFloat)sidebarFrameResizeLimit;
- (STMinMax)userDragResizeLimit;

@end


@interface STSidebarFrameView : NSView

@property (nonatomic,assign)BOOL rightSide;

@end
