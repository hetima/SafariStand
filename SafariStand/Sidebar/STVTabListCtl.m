//
//  STVTabListCtl.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "STVTabListCtl.h"
#import "STTabProxy.h"

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)setupWithTabView:(NSTabView*)tabView
{
    [self updateTabs:tabView];
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

@end
