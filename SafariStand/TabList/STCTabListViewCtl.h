//
//  STCTabListViewCtl.h
//  SafariStand
//
//  Created by hetima on 2014/10/26.
//
//

@import AppKit;

#define STTABLIST_DRAG_ITEM_TYPE @"STTABLIST_DRAG_ITEM_TYPE"

enum : NSInteger {
    sortUndefined = 0,
    sortTab = 1,
    sortDomain = 2,
    sortCreationDate = 3, // old -> new
    sortCreationDateReverse = 4, // new -> old
    sortModificationDate = 5 , // old -> new
    sortModificationDateReverse = 6, // new -> old
};

@interface STCTabListViewCtl : NSViewController

@property (nonatomic, strong) NSMutableArray* tabs;
@property (nonatomic, strong) IBOutlet NSArrayController* aryCtl;
@property (nonatomic, weak) IBOutlet NSTableView* tableView;
@property (nonatomic) NSInteger sortRule;
@property (nonatomic, readonly) BOOL dragEnabled;
@property (nonatomic, strong) NSString* statusString;

+ (STCTabListViewCtl*)viewCtl;
+ (STCTabListViewCtl*)viewCtlWithTabView:(NSTabView*)tabView;

- (void)setupWithTabView:(NSTabView*)tabView;
- (void)tabViewUpdated:(NSNotification*)note;

@end


@interface STCTabListTableView : NSTableView

@end

@interface STCTabListCellView : NSTableCellView
@property (nonatomic, weak) IBOutlet NSButton* closeButton;
@property (nonatomic, weak) STCTabListViewCtl* listViewCtl;

- (IBAction)actCloseBtn:(id)sender;

@end


@interface STCTabListCloseButtonCell : NSButtonCell

@end
