//
//  STCTabListViewCtl.m
//  SafariStand
//
//  Created by hetima on 2014/10/26.
//
//

#import "SafariStand.h"
#import "STCTabListViewCtl.h"
#import "STTabProxyController.h"
#import "STTabProxy.h"
#import "STSafariConnect.h"
#import "STCTabListGroupItem.h"
#import "STQuickSearchModule.h"

//static char tabListViewContext;

/*
 _tabPool にウインドウごとにソートして格納。 // updateTabsTargetTabView:excludesWindow:
 その後 tabs に集約。group も追加。//arrangeTabs
 
 ソートし直す必要がでたときには _tabPool 中の該当する array をソートし直して //tabViewItemUpdated:
 tabs を作り直す //arrangeTabs
 */


@interface STCTabListViewCtl ()

@end

@implementation STCTabListViewCtl {
    BOOL _parasiteMode;
    BOOL _viewAppear;
    NSMutableArray* _tabPool; //array of array
}


+ (STCTabListViewCtl*)viewCtl
{
    return [self viewCtlWithTabView:nil];
}


+ (STCTabListViewCtl*)viewCtlWithTabView:(NSTabView*)tabView
{
    STCTabListViewCtl* result;
    result=[[STCTabListViewCtl alloc]initWithNibName:@"STCTabListViewCtl" bundle:
            [NSBundle bundleWithIdentifier:kSafariStandBundleID]];
    [result setupWithTabView:tabView];
    
    return result;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


- (void)setupWithTabView:(NSTabView*)tabView
{
    _tabPool=[[NSMutableArray alloc]initWithCapacity:16];
    _sortRule=sortTab;
    _dragEnabled=YES;
    
    [self loadView];
    [self.tableView registerForDraggedTypes:@[STTABLIST_DRAG_ITEM_TYPE, @"public.url", @"public.file-url", NSStringPboardType]];
    
    if(tabView){
        _parasiteMode=YES;
        
        NSView* vew=[self.tableView enclosingScrollView];
        [vew removeFromSuperview];
        self.view=vew;
        
        [self updateTabsTargetTabView:tabView excludesWindow:nil];
    }else{
        _parasiteMode=NO;

        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewReplaced:) name:STTabViewDidReplaceNote object:nil];
        
    }
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewUpdatedNoteFromCtl:) name:
                                              STTabViewDidChangeNote object:nil];
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewItemSelected:) name:STTabViewDidSelectItemNote object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabViewItemUpdated:) name:STTabProxyDidFinishProgressNote object:nil];
    
    
}


- (void)setSortRule:(NSInteger)sortRule
{
    if (_sortRule==sortRule) {
        return;
    }
    
    _sortRule=sortRule;
    if (sortRule==sortTab) {
        _dragEnabled=YES;
    }else{
        _dragEnabled=NO;
    }
    
    if ([_tabPool count]>0) {
        NSTabView* tabView=nil;
        if (_parasiteMode) {
            tabView=STSafariTabViewForWindow(self.view.window);
        }
        
        [self updateTabsTargetTabView:tabView excludesWindow:nil];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewWillAppear
{
    [super viewWillAppear];
    
    _viewAppear=YES;
    
    if (!_parasiteMode){
        [self updateTabsTargetTabView:nil excludesWindow:nil];
    }
}


- (void)viewDidDisappear
{
    [super viewDidDisappear];
    
    _viewAppear=NO;
    
    if (!_parasiteMode){
        self.tabs=nil;
        [_tabPool removeAllObjects];
    }
    //_parasiteMode の場合この後 dealloc される
}


- (void)windowWillClose:(NSNotification*)note
{
    id winCtl=[[note object]windowController];
    if([[winCtl className]isEqualToString:kSafariBrowserWindowController]){
        [self updateTabsTargetTabView:nil excludesWindow:[note object]];
    }
}


//unused
- (void)tabViewItemSelected:(NSNotification*)note
{
    if (_parasiteMode) {
        NSTabView* tabView=[note object];
        if (self.view.window==[tabView window]) {
            //もうちょっとうまい方法はあるだろうけど
            [self.tableView reloadData];
        }
    }else{
        [self.tableView reloadData];
    }
}


//BrowserWindowControllerMac
- (void)tabViewUpdatedNoteFromCtl:(NSNotification*)note
{
    NSTabView* tabView=STSafariTabViewForBrowserWindowCtl([note object]);
    [self _tabViewUpdated:tabView];
}

//NSTabView
- (void)tabViewReplaced:(NSNotification*)note
{
    NSTabView* tabView=[note object];
    [self _tabViewUpdated:tabView];
}

- (void)_tabViewUpdated:(NSTabView*)tabView
{
    if (_parasiteMode) {
        if (!tabView) {
            tabView=STSafariTabViewForWindow(self.view.window);
        }
        
        //window 基準でチェックしてるので tabView ごと入れ替わっても大丈夫
        if (self.view.window==[tabView window]) {
            [self updateTabsTargetTabView:tabView excludesWindow:nil];
        }
        
    }else{
        //新規ウインドウはこの時点ではisVisible==NO
        [self updateTabsTargetTabView:nil excludesWindow:nil];
    }
}


//ソートし直す必要がでたときには _tabPool 中の該当する array をソートし直す
- (void)tabViewItemUpdated:(NSNotification*)note
{
    if (_sortRule==sortTab||_sortRule==sortCreationDate) {
        return;
    }
    STTabProxy* proxy=[note object];
    if (![_tabs containsObject:proxy]) {
        return;
    }
    
    __block NSUInteger poolIndex=NSNotFound;
    [_tabPool enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj containsObject:proxy]) {
            poolIndex=idx;
            *stop=YES;
        }
    }];
    
    if (poolIndex!=NSNotFound) {
        NSArray* tabToSort=[_tabPool objectAtIndex:poolIndex];
        tabToSort=[self sortTabs:tabToSort withRule:_sortRule];
        [_tabPool replaceObjectAtIndex:poolIndex withObject:tabToSort];
    }
    
    [self arrangeTabs];
}


// _tabPool にウインドウごとにソートして格納
- (void)updateTabsTargetTabView:(NSTabView*)tabView excludesWindow:(NSWindow*)excludesWindow
{
    if (!_parasiteMode && !_viewAppear) {
        return;
    }
    
    [_tabPool removeAllObjects];

    if (tabView) {
        NSArray* tabs=[STTabProxyController tabProxiesForTabView:tabView];
        [_tabPool addObject:[self sortTabs:tabs withRule:_sortRule]];
    }else{
    
        STSafariEnumerateBrowserWindow(^(NSWindow *window, NSWindowController *winCtl, BOOL *stop) {
            //ウインドウをまたいでのタブ移動中に出るウインドウを除外する
            NSInteger windowType=0;
            if ([winCtl respondsToSelector:@selector(windowType)]) {
                windowType=(NSInteger)objc_msgSend(winCtl, @selector(windowType));
            }
            if (excludesWindow==window || !(windowType==0||windowType==1)) {
                return;
            }
            
            NSArray* tabs=[STTabProxyController tabProxiesForWindow:window];
            if ([tabs count]>0) {
                [_tabPool addObject:[self sortTabs:tabs withRule:_sortRule]];
            }
            
        });
    }

    [self arrangeTabs];
}


// _tabPool を tabs に集約。group も追加
- (void)arrangeTabs
{
    NSMutableArray* ary=[[NSMutableArray alloc]init];
    for (NSArray* tabs in _tabPool) {
        if ([tabs count]>0) {

            if (!_parasiteMode) {
                STCWindowGroupItem* windowGroup=[[STCWindowGroupItem alloc]init];
                windowGroup.window=[[tabs firstObject]window];
                [ary addObject:windowGroup];
            }
            
            [ary addObjectsFromArray:tabs];
        }
    }
    
    STCBottomGroupItem* bottomGroup=[[STCBottomGroupItem alloc]init];
    [ary addObject:bottomGroup];
    
    self.tabs=ary;
}


- (NSArray*)sortTabs:(NSArray*)ary withRule:(NSInteger)rule
{
    if (rule==sortTab) {
        return ary;
    }
    
    NSArray* result=[ary sortedArrayUsingComparator:^NSComparisonResult(id objL, id objR) {

        switch (rule) {
            case sortDomain:
                return [[objL domain]compare:[objR domain]];
                break;
            case sortCreationDate:
                return [[objL creationDate]compare:[objR creationDate]];
                break;
            case sortCreationDateReverse:
                return [[objR creationDate]compare:[objL creationDate]];
                break;
            case sortModificationDate:
                return [[objL modificationDate]compare:[objR modificationDate]];
                break;
            case sortModificationDateReverse:
                return [[objR modificationDate]compare:[objL modificationDate]];
                break;
            default:
                break;
        }
        
        return NSOrderedSame;
    }];
    
    return result;
}

#pragma mark - table view


- (IBAction)actTableViewClicked:(id)sender
{
    NSInteger clickedIndex=[self.tableView clickedRow];
    if (clickedIndex>=0) {
        STTabProxy* tabProxy=[self.tabs objectAtIndex:clickedIndex];
        if ([tabProxy isKindOfClass:[STTabProxy class]]) {
            [tabProxy selectTab];
            if(!_parasiteMode)[[tabProxy window]makeKeyAndOrderFront:nil];
            return;
        }else if([tabProxy isKindOfClass:[STCWindowGroupItem class]]){
            if(!_parasiteMode)[[tabProxy window]makeKeyAndOrderFront:nil];
            return;
        }
        
    }
    
    if ([[NSApp currentEvent]clickCount]==2) {
        [NSApp sendAction:@selector(newTab:) to:nil from:nil];
    }
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    // KI ME U TI
    id obj=[self.tabs objectAtIndex:row];
    if ([obj isKindOfClass:[STTabProxy class]]) {
        return 23.0;
    }else if ([obj isKindOfClass:[STCTabListGroupItem class]]){
        return [obj viewHeight];
    }
    return 20.0;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{

    id obj=[self.tabs objectAtIndex:row];
    NSString* idn=@"default";
    
    if ([obj isKindOfClass:[STTabProxy class]]) {
        idn=@"default";
        STCTabListCellView* view=[tableView makeViewWithIdentifier:idn owner:nil];
        view.listViewCtl=self;
        return view;
    }else if ([obj isKindOfClass:[STCTabListGroupItem class]]){
        idn=[obj viewIdentifier];
    }
    return [tableView makeViewWithIdentifier:idn owner:nil];
}


- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    id obj=[self.tabs objectAtIndex:row];
    if ([obj isKindOfClass:[STCTabListGroupItem class]]){
        return [obj isGroupRow];
    }
    return NO;
}

#pragma mark - menu

- (IBAction)actDoSortMenuItem:(NSMenuItem*)sender
{
    //NSInteger sort=[sender tag];
}


- (IBAction)actViewSortMenuItem:(NSMenuItem*)sender
{
    NSInteger sort=[sender tag];
    [self setSortRule:sort];
}


- (IBAction)actGoToClipboard:(NSMenuItem*)sender
{
    NSURL* url=[sender representedObject];
    if (url) {
        STSafariGoToURLWithPolicy(url, poNewTab);
    }
}


- (NSMenu*)menuForEmptyTarget
{
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@""];
    NSMenuItem* itm;
    NSMenuItem* separator=nil;
    
    //tab will created in frontmost window
    itm=[menu addItemWithTitle:@"New Tab" action:@selector(newTab:) keyEquivalent:@""];
    
    if (_parasiteMode) {
        itm=[menu addItemWithTitle:@"Move Sidebar To Far Side" action:@selector(STToggleSidebarLR:) keyEquivalent:@""];
    }else{
        itm=[menu addItemWithTitle:@"New Window" action:@selector(newDocument:) keyEquivalent:@""];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenu* submenu=[self sortMenuWithAction:@selector(actViewSortMenuItem:) target:self];
    NSMenuItem* currentState=[submenu itemWithTag:_sortRule];
    [currentState setState:NSOnState];
    itm=[menu addItemWithTitle:@"View Order" action:nil keyEquivalent:@""];
    [itm setSubmenu:submenu];
    
    separator=[NSMenuItem separatorItem];
    
    //goToClipboard
    NSURL* url=HTBestURLFromPasteboard([NSPasteboard generalPasteboard], YES);
    //BOOL goToClipboardMenuItemShown=NO;
    if (url) {
        NSString* title=LOCALIZE(@"Go To \"%@\"");
        NSString* urlStr=[url absoluteString];
        if ([urlStr length]>42) {
            urlStr=[[urlStr substringToIndex:39]stringByAppendingString:@"..."];
        }
        
        title=[NSString stringWithFormat:title, urlStr];
        if (separator) {
            [menu addItem:separator];
            separator=nil;
        }
        itm=[menu addItemWithTitle:title action:@selector(actGoToClipboard:) keyEquivalent:@""];
        [itm setTarget:self];
        [itm setRepresentedObject:url];
        
    //search Clipboard
    }else{
        NSPasteboard* pb=[NSPasteboard generalPasteboard];
        NSString* searchString=[[pb stringForType:NSStringPboardType]stand_moderatedStringWithin:255];
        NSMenu* qsMenu=nil;
        if([searchString length]){
            qsMenu=[[STQuickSearchModule si]standardQuickSearchMenuWithSearchString:searchString];
        }
        if (qsMenu) {
            NSString* title=LOCALIZE(@"Search \"%@\"");
            if ([searchString length]>42) {
                searchString=[[searchString substringToIndex:39]stringByAppendingString:@"..."];
            }
            title=[NSString stringWithFormat:title, searchString];
            if (separator) {
                [menu addItem:separator];
                separator=nil;
            }
            NSMenuItem* labelMenu=[[NSMenuItem alloc]initWithTitle:title action:nil keyEquivalent:@""];
            [labelMenu setEnabled:NO];
            [qsMenu insertItem:labelMenu atIndex:0];
            itm=[menu addItemWithTitle:@"Search Clipboard" action:nil keyEquivalent:@""];
            [itm setSubmenu:qsMenu];
        }
    }
    
    return menu;
}


- (NSMenu*)menuForTabProxy:(STTabProxy*)tabProxy
{
    if (![tabProxy isKindOfClass:[STTabProxy class]]){
        return [self menuForEmptyTarget];
    }
    
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@""];
    NSMenuItem* itm;
    NSMenuItem* separator=nil;
    
    itm=[menu addItemWithTitle:@"Close Tab" action:@selector(actClose:) keyEquivalent:@""];
    [itm setTarget:tabProxy];
    
    if ([tabProxy isThereOtherTab]) {
        itm=[menu addItemWithTitle:@"Close Other Tab" action:@selector(actCloseOther:) keyEquivalent:@""];
        [itm setTarget:tabProxy];
        
        itm=[menu addItemWithTitle:@"Move Tab To New Window" action:@selector(actMoveTabToNewWindow:) keyEquivalent:@""];
        [itm setTarget:tabProxy];
    }
    
    separator=[NSMenuItem separatorItem];
    
    if (STSafariCanReloadTab([tabProxy tabViewItem])) {
        if (separator) {
            [menu addItem:separator];
            separator=nil;
        }
        itm=[menu addItemWithTitle:@"Reload Tab" action:@selector(actReload:) keyEquivalent:@""];
        [itm setTarget:tabProxy];
        
        separator=[NSMenuItem separatorItem];
    }
    
    if (_parasiteMode) {
        if (separator) {
            [menu addItem:separator];
            separator=nil;
        }
        itm=[menu addItemWithTitle:@"Move Sidebar To Far Side" action:@selector(STToggleSidebarLR:) keyEquivalent:@""];
    }
    return menu;
}


- (NSMenu*)menuForTabListTableView:(NSTableView*)listView row:(NSInteger)row
{
    if (row==-1) {
        return [self menuForEmptyTarget];
    } else if ([self.tabs count]>row) {
        STTabProxy* tabProxy=[self.tabs objectAtIndex:row];
        return [self menuForTabProxy:tabProxy];
    }
    return nil;
}


- (NSMenu*)sortMenuWithAction:(SEL)action target:(id)target
{
    NSMenu* menu=[[NSMenu alloc]initWithTitle:@"Sort"];
    NSMenuItem* itm;
    
    itm=[menu addItemWithTitle:@"Synchronized" action:action keyEquivalent:@""];
    [itm setTag:sortTab];
    [itm setTarget:target];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    itm=[menu addItemWithTitle:@"by Domain" action:action keyEquivalent:@""];
    [itm setTag:sortDomain];
    [itm setTarget:target];
    itm=[menu addItemWithTitle:@"by Page Loaded (Older First)" action:action keyEquivalent:@""];
    [itm setTag:sortModificationDate];
    [itm setTarget:target];
    itm=[menu addItemWithTitle:@"by Page Loaded (Newer First)" action:action keyEquivalent:@""];
    [itm setTag:sortModificationDateReverse];
    [itm setTarget:target];
    itm=[menu addItemWithTitle:@"by Tab Creation (Older First)" action:action keyEquivalent:@""];
    [itm setTag:sortCreationDate];
    [itm setTarget:target];
    itm=[menu addItemWithTitle:@"by Tab Creation (Newer First)" action:action keyEquivalent:@""];
    [itm setTag:sortCreationDateReverse];
    [itm setTarget:target];
    
    return menu;
}


#pragma mark - drag and drop

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if (!_dragEnabled) {
        return NO;
    }
    
    [pboard declareTypes:@[STTABLIST_DRAG_ITEM_TYPE] owner:self];
    
    NSUInteger currentIndex = [rowIndexes firstIndex];
    
    //support only single item
    STTabProxy* selectedProxy=[_tabs objectAtIndex:currentIndex];
    if (![selectedProxy isKindOfClass:[STTabProxy class]]) {
        return NO;
    }
    NSArray* ary=@[@(currentIndex)];
    
    /*
    NSMutableArray* ary=[[NSMutableArray alloc]initWithCapacity:[rowIndexes count]];
    while (currentIndex != NSNotFound) {
        [ary addObject:@(currentIndex)];
        currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
    }
    */
    
    [pboard setPropertyList:ary forType:STTABLIST_DRAG_ITEM_TYPE];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (!_dragEnabled) {
        NSURL *aURL=HTBestURLFromPasteboard([info draggingPasteboard], NO);
        if (aURL) {
            [aTableView setDropRow:-1 dropOperation:NSTableViewDropOn];
            return NSDragOperationCopy;
        }
        return NSDragOperationNone;
    }
    
    if (operation==NSTableViewDropOn) {
        return NSDragOperationNone;
    }
    
    // KIMEUTI
    NSInteger tabsCount=[self.tabs count];
    if (row>=tabsCount) { //last item is bottom group
        [aTableView setDropRow:row-1 dropOperation:NSTableViewDropAbove];
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
    BOOL acceptDrop = NO;
    NSPasteboard *pb=[info draggingPasteboard];
    
    if (!_dragEnabled) {
        acceptDrop=[self _tryOpenPasteboard:pb atRow:-1];
        return acceptDrop;
    }
    
    if (operation==NSTableViewDropOn) {
        return NO;
    }
    
    NSArray *dragTypes = [pb types];
    
    // KIMEUTI
    NSInteger tabsCount=[self.tabs count];
    if (row>=tabsCount) { //last item is bottom group
        row=tabsCount-1;
    }
    
    if ([dragTypes containsObject:STTABLIST_DRAG_ITEM_TYPE]) {
        acceptDrop = YES;
        
        id sender=[info draggingSource]; //NSTableView
        NSArray *indexes = [pb propertyListForType:STTABLIST_DRAG_ITEM_TYPE];
        
        
        NSUInteger windowRow=NSNotFound;
        NSInteger offset=0;
        
        //the bottom of destination
        /*if (row>=tabsCount-1) {
            row=tabsCount-2;
            offset=1;
        }*/
        
        STTabProxy* tabProxyAtDestination=[_tabs objectAtIndex:row];
        
        //care above group (window or bottom)
        if ([tabProxyAtDestination isKindOfClass:[STCTabListGroupItem class]]) {
            if (row==0) {
                windowRow=0;
            }else{
                tabProxyAtDestination=[_tabs objectAtIndex:row-1];
                offset=1;
            }
        }
        
        //table index to window index
        if ([tabProxyAtDestination isKindOfClass:[STTabProxy class]]) {
            for (NSArray* windowTabs in _tabPool) {
                windowRow=[windowTabs indexOfObjectIdenticalTo:tabProxyAtDestination];
                if (windowRow!=NSNotFound) {
                    break;
                }
            }
        }
        
        if (windowRow==NSNotFound) {
            return NO;
        }
        windowRow+=offset;
        
        STCTabListViewCtl* draggedCtl=(STCTabListViewCtl*)[sender dataSource]; // self if drag from same view
        //support only single item
        STTabProxy* draggedProxy=[draggedCtl.tabs objectAtIndex:[[indexes firstObject]integerValue]];
        
        if ([draggedProxy isInPrivateBrowsing]!=[tabProxyAtDestination isInPrivateBrowsing]) {
            return NO;
        }
        
        //don't mind same window or not
        STSafariMoveTabToOtherWindow(draggedProxy.tabViewItem, [tabProxyAtDestination window], windowRow, YES);

        //drag other element
    } else {
        acceptDrop=[self _tryOpenPasteboard:[info draggingPasteboard] atRow:row];
    }
    
    return acceptDrop;
    
}


- (BOOL)_tryOpenPasteboard:(NSPasteboard*)pb atRow:(NSInteger)row
{
    NSURL *urlToGo=HTBestURLFromPasteboard(pb, YES);
    if (urlToGo) {
        if (_parasiteMode && row>=0) {
            id newTabItem=STSafariCreateWKViewOrWebViewAtIndexAndShow([[self.view window]windowController], row, YES);
            if(newTabItem){
                STTabProxy* newProxy=[STTabProxy tabProxyForTabViewItem:newTabItem];
                [newProxy goToURL:urlToGo];
            }
        }else{
            STSafariGoToURLWithPolicy(urlToGo, poNewTab);
        }
        return YES;
    }
    return NO;
}


#pragma mark - cellView

- (void)listCellViewMouseEntered:(STCTabListCellView*)cellView
{
    STTabProxy* proxy=[cellView objectValue];
    if ([proxy isKindOfClass:[STTabProxy class]]) {
        NSString* urlStr=[proxy URLString];
        self.statusString=urlStr;
    }
}


- (void)listCellViewMouseExited:(STCTabListCellView*)cellView
{
    self.statusString=@"";
}

@end


#pragma mark - Support Classes


@implementation STCTabListTableView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
    STCTabListViewCtl* viewCtl=(STCTabListViewCtl*)self.delegate;
    return [viewCtl menuForTabListTableView:self row:row];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
    LOG(@"%@", NSStringFromRect(clipRect));
}
@end



@implementation STCTabListCellView

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow]; 
}



- (IBAction)actCloseBtn:(id)sender
{
    STTabProxy* tabProxy=[self objectValue];
    [tabProxy actClose:self];
}


-(void)drawRect:(NSRect)dirtyRect
{
    static NSColor* borderColor;
    static NSColor* lineColor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        borderColor=[NSColor colorWithCalibratedRed:1.0f/255.0f green:100.0f/255.0f blue:175.0f/255.0f alpha:0.2];
        lineColor=[NSColor colorWithWhite:0.82 alpha:1.0];
    });
    
    STTabProxy* tabProxy=[self objectValue];
    if (tabProxy.isSelected) {
        [borderColor setFill];
        [NSBezierPath fillRect:self.bounds];

    }else{
        [lineColor setStroke];
        [NSBezierPath setDefaultLineWidth:0.0f];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(self.bounds), NSMaxY(self.bounds))
                                  toPoint:NSMakePoint(NSMaxX(self.bounds), NSMaxY(self.bounds))];
    }
}


#pragma mark - objectValue

- (void)setObjectValue:(id)objectValue
{
    id old=self.objectValue;
    [super setObjectValue:objectValue];
    if (objectValue!=old) {
        if ([objectValue isKindOfClass:[STTabProxy class]]) {
            [objectValue addObserver:self forKeyPath:@"isSelected" options:(NSKeyValueObservingOptionNew) context:nil];
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(tabProxyBecameInvalid:) name:STTabProxyBecameInvalidNote object:objectValue];
        }
        if ([old isKindOfClass:[STTabProxy class]]) {
            [old removeObserver:self forKeyPath:@"isSelected"];
            [[NSNotificationCenter defaultCenter]removeObserver:self name:STTabProxyBecameInvalidNote object:old];
        }
    }
}


- (void)tabProxyBecameInvalid:(NSNotification*)note
{
    if (self.objectValue==[note object]) {
        self.objectValue=nil;
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"isSelected"]) {
        [self setNeedsDisplay:YES];
    }else{
        /*[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];*/
    }
}



@end

@implementation STCTabListCloseButtonCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.showsBorderOnlyWhileMouseInside=YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.showsBorderOnlyWhileMouseInside=YES;
    }
    return self;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (_bcFlags2.mouseInside) {
        NSImage* img=[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];
        [self drawImage:img withFrame:cellFrame inView:controlView];
    } else {
        [super drawInteriorWithFrame:cellFrame
                              inView:controlView];
    }
}

@end
