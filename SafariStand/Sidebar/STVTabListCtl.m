//
//  STVTabListCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STVTabListCtl.h"
#import "STTabProxy.h"
#import "HTUtils.h"
#import "STSafariConnect.h"
#import "HTWebKit2Adapter.h"

@interface STVTabListCtl ()

@end

@implementation STVTabListCtl
{
    BOOL _ignoreObserve;
}

+(STVTabListCtl*)viewCtl
{
    
    STVTabListCtl* result=[[STVTabListCtl alloc]initWithNibName:@"STVTabListCtl" bundle:
                          [NSBundle bundleWithIdentifier:kSafariStandBundleID]];
    
    return result;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self.oTableView registerForDraggedTypes:@[STTABLIST_DRAG_ITEM_TYPE, @"public.url", @"public.file-url", NSStringPboardType]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)setupWithTabView:(NSTabView*)tabView
{
    if(tabView)[self updateTabs:tabView];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewUpdated:) name:STTabViewDidChangeNote object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewItemSelected:) name:STTabViewDidSelectItemNote object:nil];
    
}

- (void)updateTabs:(NSTabView*)tabView
{
    NSMutableArray *currentTabs=[STTabProxyController tabProxiesForTabView:tabView];
    self.tabs=currentTabs;
    
}

- (void)tabViewUpdated:(NSNotification*)note
{
    NSTabView* tabView=[note object];
    if (self.view.window==[tabView window]) {
        [self updateTabs:tabView];
    }
}

- (void)tabViewItemSelected:(NSNotification*)note
{
    NSTabView* tabView=[note object];
    if (self.view.window==[tabView window]) {
        [self takeSelectionFromTabView:tabView];
    }
}

- (void)takeSelectionFromTabView:(NSTabView*)tabView
{
    NSTabViewItem *itm=[tabView selectedTabViewItem];
    STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:itm];
    if (proxy) {
        BOOL prevObserve=_ignoreObserve;
        //NSUInteger idx=[self.tabs indexOfObject:proxy];
        _ignoreObserve=YES;

        
        _ignoreObserve=prevObserve;
    }
}

#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    [pboard declareTypes:@[STTABLIST_DRAG_ITEM_TYPE] owner:self];
    
    NSMutableArray* ary=[[NSMutableArray alloc]initWithCapacity:[rowIndexes count]];
    NSUInteger currentIndex = [rowIndexes firstIndex];
    while (currentIndex != NSNotFound) {
        [ary addObject:@(currentIndex)];
        currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
    }
    [pboard setPropertyList:ary forType:STTABLIST_DRAG_ITEM_TYPE];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation==NSTableViewDropOn) {
        return NSDragOperationNone;
    }
    
    NSArray *dragTypes = [[info draggingPasteboard]types];
    if([dragTypes containsObject:STTABLIST_DRAG_ITEM_TYPE]){
        return NSDragOperationMove;
    }
    
    
    NSURL *aURL=HTBestURLFromPasteboard([info draggingPasteboard], NO);
    if (aURL) {
        return NSDragOperationCopy;
    }

    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    if (operation==NSTableViewDropOn) {
        return NO;
    }
    
    BOOL acceptDrop = NO;
    NSPasteboard *pb=[info draggingPasteboard];
    NSArray *dragTypes = [pb types];
    
    if ([dragTypes containsObject:STTABLIST_DRAG_ITEM_TYPE]) {
        acceptDrop = YES;
        id sender=[info draggingSource];
        if (sender==self) {
            
        }else{
            
        }
        
    } else {
        NSURL *urlToGo=HTBestURLFromPasteboard([info draggingPasteboard], YES);
        if (urlToGo) {
            acceptDrop = YES;
            
            _ignoreObserve=YES;
            
            id newTabItem=STSafariCreateWKViewOrWebViewAtIndexAndShow([aTableView window], row, YES);
            if(newTabItem){
                STTabProxy* newProxy=[STTabProxy tabProxyForTabViewItem:newTabItem];
                [newProxy goToURL:urlToGo];
            }
            _ignoreObserve=NO;
            
            [self updateTabs:[newTabItem tabView]];
        }
    }

    return acceptDrop;

}
@end
