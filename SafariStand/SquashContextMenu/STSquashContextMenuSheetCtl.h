//
//  STSquashContextMenuSheetCtl.h
//  SafariStand


@import AppKit;

@interface STSquashContextMenuSheetCtl : NSWindowController

@property (nonatomic, retain) NSMutableArray* menuItemDefs;

- (IBAction)actSheetDone:(id)sender;

@end
