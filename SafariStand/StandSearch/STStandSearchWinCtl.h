//
//  STStandSearchWinCtl.h
//  SafariStand

#import <Cocoa/Cocoa.h>
@class STStandSearchViewCtl;
@interface STStandSearchWinCtl : NSWindowController{
    STStandSearchViewCtl* viewCtl;
}
@property(nonatomic,retain)STStandSearchViewCtl* viewCtl;

+ (void)showStandSearcWindow;

@end
