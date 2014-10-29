//
//  STCTabListViewCtl.h
//  SafariStand
//
//  Created by hetima on 2014/10/26.
//
//

#import <Cocoa/Cocoa.h>

#define STTABLIST_DRAG_ITEM_TYPE @"STTABLIST_DRAG_ITEM_TYPE"

enum : NSInteger {
    sortTab =0,
    sortDomain,
    sortCreationDate,
    sortModificationDate,
};

@interface STCTabListViewCtl : NSViewController

@property(nonatomic, strong) NSMutableArray* tabs;
@property(nonatomic, strong) IBOutlet NSArrayController* aryCtl;
@property(nonatomic, weak) IBOutlet NSTableView* tableView;
@property(nonatomic) NSInteger sortStyle;
@property (nonatomic, readonly) BOOL dragDropEnabled;

+ (STCTabListViewCtl*)viewCtl;
+ (STCTabListViewCtl*)viewCtlWithTabView:(NSTabView*)tabView;

- (void)setupWithTabView:(NSTabView*)tabView;
- (void)tabViewUpdated:(NSNotification*)note;

@end


@interface STCTabListTableView : NSTableView

//@property (nonatomic, unsafe_unretained) IBOutlet STVTabListCtl *oTabListCtl;

@end

@interface STCTabListCellView : NSTableCellView
@property (nonatomic) BOOL mouseIsIn;

- (IBAction)actCloseBtn:(id)sender;

@end
