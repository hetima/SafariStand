//
//  STSidebarResizeHandleView.h
//  SafariStand

@import AppKit;

@protocol STSidebarResizeHandleViewDelegate;

@interface STSidebarResizeHandleView : NSView

@property (nonatomic, unsafe_unretained) IBOutlet id <STSidebarResizeHandleViewDelegate> delegate;

@property (nonatomic,assign) NSView* leftView;
@property (nonatomic,assign) NSView* rightView;
@property (nonatomic,assign) STMinMax resizeLimit;

@end

@protocol STSidebarResizeHandleViewDelegate <NSObject>

@required
- (void)sidebarResizeHandleWillStartTracking:(STSidebarResizeHandleView*)resizeHandle;

@optional
- (void)sidebarResizeHandleDidEndTracking:(STSidebarResizeHandleView*)resizeHandle;


@end