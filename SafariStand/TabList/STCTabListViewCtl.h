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
    sortCreationDateReverse,
    sortModificationDate,
    sortModificationDateReverse,
};

@interface STCTabListViewCtl : NSViewController

@property(nonatomic, strong) NSMutableArray* tabs;
@property(nonatomic, strong) IBOutlet NSArrayController* aryCtl;
@property(nonatomic, weak) IBOutlet NSTableView* tableView;
@property(nonatomic) NSInteger sortRule;
@property(nonatomic, readonly) BOOL dragDropEnabled;
@property(nonatomic, strong) NSString* statusString;

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
@property(nonatomic, weak) STCTabListViewCtl* listViewCtl;

- (IBAction)actCloseBtn:(id)sender;

@end
