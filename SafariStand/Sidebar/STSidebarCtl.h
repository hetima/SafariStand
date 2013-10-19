//
//  STSidebarCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

#define kCounterpartMinWidth 100
#define kSidebarFrameMinWidth 200
#define kSidebarFrameMaxWidth 800

@class DMTabBar, STSidebarResizeHandleView, STVTabListCtl;

@interface STSidebarCtl : NSViewController <NSTabViewDelegate>

@property (nonatomic,strong) STVTabListCtl* tabListCtl;

@property (weak) IBOutlet NSSplitView *oSplitView;
@property (weak) IBOutlet DMTabBar *oPrimaryTabbar;
@property (weak) IBOutlet DMTabBar *oSecondaryTabbar;
@property (weak) IBOutlet STSidebarResizeHandleView *oResizeHandle;
@property (weak) IBOutlet NSTabView* oPrimaryTabView;
@property (weak) IBOutlet NSTabView* oSecondaryTabView;

@property (nonatomic,weak)NSTabView* targetView;
@property (nonatomic,weak)NSView* counterpartView;

+ (STSidebarCtl*)viewCtl;

- (void)installToTabView:(NSTabView*)view sidebarWidth:(CGFloat)width rightSide:(BOOL)rightSide;
- (void)uninstallFromTabView;

- (BOOL)rightSide;
- (void)setRightSide:(BOOL)rightSide;

- (CGFloat)counterpartResizeLimit;
- (CGFloat)sidebarFrameResizeLimit;
- (STMinMax)userDragResizeLimit;

@end


@interface STSidebarFrameView : NSView

@property (nonatomic,assign)BOOL rightSide;

@end
