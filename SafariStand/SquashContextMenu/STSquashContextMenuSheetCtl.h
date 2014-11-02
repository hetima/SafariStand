//
//  STSquashContextMenuSheetCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

@interface STSquashContextMenuSheetCtl : NSWindowController

@property (nonatomic, retain) NSMutableArray* menuItemDefs;

- (IBAction)actSheetDone:(id)sender;

@end
