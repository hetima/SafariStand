//
//  SquashContextMenuSheetCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@interface SquashContextMenuSheetCtl : NSWindowController

@property (nonatomic, retain)NSMutableArray* menuItemDefs;

- (IBAction)actSheetDone:(id)sender;

@end
