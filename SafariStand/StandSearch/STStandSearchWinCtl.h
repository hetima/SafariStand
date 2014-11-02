//
//  STStandSearchWinCtl.h
//  SafariStand

#import <Cocoa/Cocoa.h>

@class STStandSearchViewCtl;

@interface STStandSearchWinCtl : NSWindowController

@property (nonatomic,retain) STStandSearchViewCtl* viewCtl;

+ (void)showStandSearcWindow;

@end
