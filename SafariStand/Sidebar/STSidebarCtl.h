//
//  STSidebarCtl.h
//  SafariStand


@import AppKit;

#define kCounterpartMinWidth 100
#define kSidebarFrameMinWidth 36
#define kSidebarFrameDefaultWidth 160
#define kSidebarFrameMaxWidth 800

@class DMTabBar, STSidebarResizeHandleView, STCTabListViewCtl;

@interface STSidebarCtl : NSViewController <NSTabViewDelegate>

@property (nonatomic, strong) STCTabListViewCtl* tabListCtl;

@property (nonatomic, weak) IBOutlet NSSplitView *oSplitView;
@property (nonatomic, weak) IBOutlet DMTabBar *oPrimaryTabbar;
@property (nonatomic, weak) IBOutlet DMTabBar *oSecondaryTabbar;
@property (nonatomic, weak) IBOutlet STSidebarResizeHandleView *oResizeHandle;
@property (nonatomic, weak) IBOutlet NSTabView* oPrimaryTabView;
@property (nonatomic, weak) IBOutlet NSTabView* oSecondaryTabView;

@property (nonatomic, weak) NSTabView* targetView;
@property (nonatomic, weak) NSView* counterpartView;

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
