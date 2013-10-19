//
//  STVTabListCtl.h
//  SafariStand


#import <Cocoa/Cocoa.h>

#define STTABLIST_DRAG_ITEM_TYPE @"STTABLIST_DRAG_ITEM_TYPE"


@interface STVTabListCtl : NSViewController

@property (nonatomic,strong) NSMutableArray* tabs;
@property (weak) IBOutlet NSTableView *oTableView;

+(STVTabListCtl*)viewCtl;

- (void)setupWithTabView:(NSTabView*)tabView;
- (void)uninstallFromTabView;

- (IBAction)actTableViewClicked:(id)sender;

@end



@interface STVTabListTableView : NSTableView

@property (weak) IBOutlet STVTabListCtl *oTabListCtl;

@end


@interface STVTabListCellView : NSTableCellView

- (IBAction)actCloseBtn:(id)sender;

@end


@interface STVTabListButton : NSButton

@end


@interface STVTabListButtonCell : NSButtonCell

@end

