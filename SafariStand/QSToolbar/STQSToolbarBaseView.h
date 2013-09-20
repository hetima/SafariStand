//
//  STQSToolbarBaseView.h
//  SafariStand


#import <Cocoa/Cocoa.h>

#define kSTQSToolbarBaseWidth 200
#define kSTQSToolbarLeftWidth 64

@class STQuickSearch, STQSToolbarSearchView;

@interface STQSToolbarBaseView : NSView
@property(nonatomic, assign) STQSToolbarSearchView* rightView;

- (id)initWithQuickSearch:(STQuickSearch*)qs;

@end