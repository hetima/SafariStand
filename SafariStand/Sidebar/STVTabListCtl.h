//
//  STVTabListCtl.h
//  SafariStand


@import AppKit;

#define STTABLIST_DRAG_ITEM_TYPE @"STTABLIST_DRAG_ITEM_TYPE"


@interface STVTabListCtl : NSViewController

@property (nonatomic,strong) NSMutableArray* tabs;
@property (weak) IBOutlet NSTableView *oTableView;

+(STVTabListCtl*)viewCtl;

- (void)setupWithTabView:(NSTabView*)tabView;
- (void)uninstallFromTabView;

- (IBAction)actTableViewClicked:(id)sender;
- (void)tabViewUpdated:(NSNotification*)note;
@end



@interface STVTabListTableView : NSTableView

@property (nonatomic, unsafe_unretained) IBOutlet STVTabListCtl *oTabListCtl;

@end


@interface STVTabListCellView : NSTableCellView

- (IBAction)actCloseBtn:(id)sender;

@end


@interface STVTabListButton : NSButton

@end


@interface STVTabListButtonCell : NSButtonCell

@end

