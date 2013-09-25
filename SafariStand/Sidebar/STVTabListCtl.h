//
//  STVTabListCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@interface STVTabListCtl : NSViewController

@property (nonatomic,strong) NSMutableArray* tabs;

+(STVTabListCtl*)viewCtl;

- (void)setupWithTabView:(NSTabView*)tabView;

@end
