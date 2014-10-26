//
//  STCTabListViewCtl.h
//  SafariStand
//
//  Created by hetima on 2014/10/26.
//
//

#import <Cocoa/Cocoa.h>

@interface STCTabListViewCtl : NSViewController

@property(nonatomic, strong) NSMutableArray* allTabs;
@property(nonatomic, strong) IBOutlet NSArrayController* aryCtl;

+ (STCTabListViewCtl*)viewCtl;

@end
