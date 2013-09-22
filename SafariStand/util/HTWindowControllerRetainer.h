//
//  HTWindowControllerRetainer.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@interface HTWindowControllerRetainer : NSObject

@property (nonatomic,strong)NSMutableArray* windowControllers;

+ (HTWindowControllerRetainer *)si;
- (void)addWondowController:(NSWindowController*)winCtl;

@end
