//
//  HTWindowControllerRetainer.h
//  SafariStand


@import AppKit;

@interface HTWindowControllerRetainer : NSObject

@property (nonatomic,strong)NSMutableArray* windowControllers;

+ (HTWindowControllerRetainer *)si;
- (void)addWindowController:(NSWindowController*)winCtl;

@end
