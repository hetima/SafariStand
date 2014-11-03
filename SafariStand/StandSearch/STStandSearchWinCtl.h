//
//  STStandSearchWinCtl.h
//  SafariStand

@import AppKit;

@class STStandSearchViewCtl;

@interface STStandSearchWinCtl : NSWindowController

@property (nonatomic,retain) STStandSearchViewCtl* viewCtl;

+ (void)showStandSearcWindow;

@end
