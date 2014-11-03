//
//  STQSToolbarBaseView.h
//  SafariStand


@import AppKit;

#define kSTQSToolbarBaseWidth 200
#define kSTQSToolbarLeftWidth 64

@class STQuickSearchModule, STQSToolbarSearchView;

@interface STQSToolbarBaseView : NSView
@property (nonatomic, assign) STQSToolbarSearchView* rightView;

- (id)initWithQuickSearch:(STQuickSearchModule*)qs;

@end

