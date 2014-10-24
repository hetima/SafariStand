//
//  STTabProxy.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import <Quartz/Quartz.h>

#import "SafariStand.h"
#import "STTabProxy.h"
#import "STTabProxyController.h"

#import "HTWebKit2Adapter.h"
#import "STFakeJSCommand.h"

@implementation STTabProxy
{
    BOOL _invalid;
    void* _pageRef;
}

- (void)goToURL:(NSURL*)urlToGo
{
    htWKGoToURL([self wkView], urlToGo);
}

+(STTabProxy*)tabProxyForWKView:(id)wkView
{
    return [STSafariTabViewItemForWKView(wkView) htao_valueForKey:@"STTabProxy"];
}

+(STTabProxy*)tabProxyForTabViewItem:(id)item
{
    return [item htao_valueForKey:@"STTabProxy"];
}


- (id)initWithTabViewItem:(id)item
{
    self = [super init];
    if (self) {
        _ownRef=(uintptr_t)(self);

        // Initialization code here.
        [item htao_setValue:self forKey:@"STTabProxy"];
        _tabViewItem=item;
        _cachedImage=nil;
        _isLoading=NO;
        _wantsImage=YES; //test
        _isMarked=NO;
        _isUnread=NO;
        _isInAnyWidget=NO;
        _invalid=NO;

        [[STTabProxyController si]addTabProxy:self];
        self.title=[item title];
        //まだwindowに入ってない
        [[NSNotificationCenter defaultCenter]postNotificationName:STTabProxyCreatedNote object:self];
    }
    
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fetchIconImage) object:nil];
    LOG(@"STTabProxy dealloc");
}

- (id)window
{
    id winCtl=STSafariBrowserWindowControllerForWKView([self wkView]);
    return [winCtl window];
}

- (id)wkView
{
    return STSafariWKViewForTabViewItem(_tabViewItem);
}

- (void*)pageRef
{
    if (!_pageRef) {
        _pageRef=(void*)htWKPageRefForWKView([self wkView]);
    }
    return _pageRef;
}

-(BOOL)canClose
{
    if([[_tabViewItem tabView]numberOfTabViewItems]>1)return YES;
    return NO;
    /*
    if ([tabViewItem respondsToSelector:@selector(canBeClosed)]) {
        return (BOOL)objc_msgSend(tabViewItem, @selector(canBeClosed));
    }
    return NO;
     */
}

-(BOOL)isThereOtherTab
{
    if([[_tabViewItem tabView]numberOfTabViewItems]>1)return YES;
    
    return NO;
}


- (NSString*)URLString
{
    return [_tabViewItem URLString];
}


-(NSString*)imagePathForExt:(NSString*)ext
{
    return STSafariThumbnailForURLString([self URLString], ext);

}


-(NSImage*)image
{
    return self.cachedImage;
}

-(NSImage*)icon
{
    return self.cachedImage;
}

- (NSTabView *)tabView
{
    return [_tabViewItem tabView];
}

-(void)selectTab
{
    if([_tabViewItem tabState]==NSSelectedTab)return;
    
    id ctl=STSafariBrowserWindowControllerForWKView([self wkView]);
    //Safari 6
    if ([ctl respondsToSelector:@selector(_showTab:)]) {
        objc_msgSend(ctl, @selector(_showTab:), _tabViewItem);
    //Safari 7
    }else if ([ctl respondsToSelector:@selector(_selectTab:)]) {
        objc_msgSend(ctl, @selector(_selectTab:), _tabViewItem);
    }
    
    //[[tabViewItem tabView]selectTabViewItem:tabViewItem];
}


#pragma mark - pageLoader

-(void)didStartProgress
{
    LOG(@"didStartProgress");
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fetchIconImage) object:nil];
    //[self willChangeValueForKey:@"isLoading"];
    self.isLoading=YES;
    //[self didChangeValueForKey:@"isLoading"];
    
    [self willChangeValueForKey:@"image"];
    self.cachedImage=nil;
    [self didChangeValueForKey:@"image"];
    
    //self.domain=@"";
    
}

-(void)didFinishProgress
{
    LOG(@"didFinishProgress");

    //[self willChangeValueForKey:@"isLoading"];
    self.isLoading=NO;
    if([_tabViewItem tabState]!=NSSelectedTab)self.isUnread=YES;

    //[self didChangeValueForKey:@"isLoading"];
    self.title=[self.tabViewItem title];
    self.domain=[[NSURL URLWithString:[self URLString]] host];

    if ((self.wantsImage || self.isInAnyWidget) && [self.domain length]>0) {
        if (![self fetchIconImage]) {
            [self performSelector:@selector(fetchIconImage) withObject:nil afterDelay:2.5];
            [self performSelector:@selector(fetchIconImage) withObject:nil afterDelay:7.0];
        }
    }
}

-(void)installedToSidebar:(id)ctl
{
    self.isInAnyWidget=YES;
    if (!self.wantsImage) {
        [self fetchIconImage];
    }
}

//This method may be called after target tab has closed.
-(void)uninstalledFromSidebar:(id)ctl
{
    self.isInAnyWidget=NO;
    if (!self.wantsImage) {
        self.cachedImage=nil;
    }
}

-(BOOL)fetchIconImage
{
    if (!self.domain) {
        return NO;
    }
    
    id wkView=self.wkView;
    if (wkView) {
        NSImage* icon=htWKIconImageForWKView(wkView, 32.0);
        if (icon) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fetchIconImage) object:nil];
            [self willChangeValueForKey:@"image"];
            self.cachedImage=icon;
            [self didChangeValueForKey:@"image"];
            return YES;
        }
    }
    LOG(@"fail fetchIconImage");
    return NO;
}

#pragma mark - IBAction

- (IBAction)actClose:(id)sender
{
    if (_invalid) return; //連続呼び出し対策
    
    id winCtl=STSafariBrowserWindowControllerForWKView([self wkView]);
    if (![self canClose]) {
        [[winCtl window]performClose:nil];
    }else{
        //BrowserWindowControllerMac - (void)tryToCloseTabWhenReady:(NSTabViewItem*)arg1;
        if ([winCtl respondsToSelector:@selector(tryToCloseTabWhenReady:)]) {
            _invalid=YES;
            objc_msgSend(winCtl, @selector(tryToCloseTabWhenReady:), _tabViewItem);
        }
    }
    
}

- (IBAction)actCloseOther:(id)sender
{
    if (![self isThereOtherTab]||_invalid) return;
    
    
    //BrowserWindowControllerMac - (void)tryToCloseOtherTabsWhenReady:(NSTabViewItem*)arg1;
    id winCtl=STSafariBrowserWindowControllerForWKView([self wkView]);
    if ([winCtl respondsToSelector:@selector(tryToCloseOtherTabsWhenReady:)]) {
        objc_msgSend(winCtl, @selector(tryToCloseOtherTabsWhenReady:), _tabViewItem);
    }
}

- (IBAction)actReload:(id)sender
{
    STSafariReloadTab(self.tabViewItem);
}

- (IBAction)actMoveTabToNewWindow:(id)sender
{
    if (![self isThereOtherTab]||_invalid) return;
    STSafariMoveTabToNewWindow(self.tabViewItem);
}


@end

