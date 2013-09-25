//
//  STSidebarCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

#define kCounterpartMinWidth 100
#define kSidebarFrameMinWidth 200

@class DMTabBar, STSidebarResizeHandleView, STVTabListCtl;

@interface STSidebarCtl : NSViewController <NSTabViewDelegate>

@property (nonatomic,strong) STVTabListCtl* tabListCtl;

@property (weak) IBOutlet DMTabBar *oPrimaryTabbar;
@property (weak) IBOutlet DMTabBar *oSecondaryTabbar;
@property (weak) IBOutlet STSidebarResizeHandleView *oResizeHandle;
@property (weak) IBOutlet NSTabView* oPrimaryTabView;
@property (weak) IBOutlet NSTabView* oSecondaryTabView;

@property (nonatomic,assign)NSView* counterpartView;

+ (STSidebarCtl*)viewCtl;
+(STSidebarCtl*)viewCtlWithCounterpartView:(NSView*)view;

- (BOOL)rightSide;
- (void)setRightSide:(BOOL)rightSide;

- (CGFloat)counterpartResizeLimit;
- (CGFloat)sidebarFrameResizeLimit;
- (STMinMax)userDragResizeLimit;

@end


@interface STSidebarFrameView : NSView

@property (nonatomic,assign)BOOL rightSide;

@end
