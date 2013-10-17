//
//  STVTabListCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STVTabListCtl.h"
#import "STTabProxy.h"
#import "STTabProxyController.h"
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

- (void)uninstallFromTabView
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.tabs makeObjectsPerformSelector:@selector(uninstalledFromSidebar:) withObject:self];
}

- (void)updateTabs:(NSTabView*)tabView
{
    NSMutableArray *previousTabs=self.tabs;
    NSMutableArray *currentTabs=[STTabProxyController tabProxiesForTabView:tabView];
    for (STTabProxy* proxy in currentTabs) {
        [previousTabs removeObjectIdenticalTo:proxy];
        [proxy installedToSidebar:self];
    }
    
    //ここで残ってるのは閉じられたタブと移動中一時的に外されたタブ
    [previousTabs makeObjectsPerformSelector:@selector(uninstalledFromSidebar:) withObject:self];
    
    self.tabs=currentTabs;
    
}

- (void)tabViewUpdated:(NSNotification*)note
{
    NSTabView* tabView=[note object];
    //window 基準でチェックしてるので tabView ごと入れ替わっても大丈夫
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
        
        id sender=[info draggingSource]; //NSTableView
        NSArray *indexes = [pb propertyListForType:STTABLIST_DRAG_ITEM_TYPE];

        //drag from same view
        if (sender==aTableView) {
            _ignoreObserve=YES;
            NSMutableArray* aboveArray=[NSMutableArray array];
            NSMutableArray* insertedArray=[NSMutableArray array];
            NSMutableArray* belowArray=[NSMutableArray array];
            
            NSInteger i;
            NSInteger cnt=[self.tabs count];
            for (i=0; i<cnt; i++) {
                STTabProxy* tabProxy=[self.tabs objectAtIndex:i];
                if ([indexes containsObject:[NSNumber numberWithInteger:i]]) {
                    [insertedArray addObject:tabProxy];
                }else if (i<row) {
                    [aboveArray addObject:tabProxy];
                }else{
                    [belowArray addObject:tabProxy];
                }
            }
            [aboveArray addObjectsFromArray:insertedArray];
            [aboveArray addObjectsFromArray:belowArray];
            cnt=[aboveArray count];
            for (i=0; i<cnt; i++) {
                STTabProxy* tabProxy=[aboveArray objectAtIndex:i];
                
                STSafariMoveTabViewItemToIndex(tabProxy.tabViewItem, i);
            }
            _ignoreObserve=NO;
            self.tabs=aboveArray;
            
        //drag from other view
        }else if([[sender dataSource]isKindOfClass:[STVTabListCtl class]]) {
            STVTabListCtl* draggedCtl=(STVTabListCtl*)[sender dataSource];
            NSEnumerator* e=[indexes reverseObjectEnumerator];
            NSNumber* index;
            while (index=[e nextObject]) {
                STTabProxy* draggedProxy=[draggedCtl.tabs objectAtIndex:[index integerValue]];
                STSafariMoveTabToOtherWindow(draggedProxy.tabViewItem, [aTableView window], row, YES);
            }
        }
    //drag other element
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

@implementation STVTabListCellView

- (IBAction)actCloseBtn:(id)sender
{
    STTabProxy* tabProxy=[self objectValue];
    [tabProxy actClose:self];
}

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSColor lightGrayColor] setStroke];
    [NSBezierPath setDefaultLineWidth:0.0f];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(self.bounds), NSMinY(self.bounds))
                              toPoint:NSMakePoint(NSMaxX(self.bounds), NSMinY(self.bounds))];
}

@end



@implementation STVTabListButton

@end



@implementation STVTabListButtonCell

-(void)awakeFromNib
{
    NSImage* image=[self image];

    NSImage* lightImage=({
        NSImage* lightImage=[[NSImage alloc]initWithSize:[image size]];
        [lightImage lockFocus];
        NSRect rect=NSZeroRect;
        rect.size=[image size];
        [image drawAtPoint:NSZeroPoint fromRect:rect operation:NSCompositeCopy fraction:0.33];
        [lightImage unlockFocus];
        lightImage;
    });
    
    [self setAlternateImage:image];
    [self setImage:lightImage];
    
}

@end
