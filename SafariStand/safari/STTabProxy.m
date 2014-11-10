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
    NSString* _cachedDomain;
}


- (void)goToURL:(NSURL*)urlToGo
{
    htWKGoToURL([self wkView], urlToGo);
}


+ (STTabProxy*)tabProxyForWKView:(id)wkView
{
    return [STSafariTabViewItemForWKView(wkView) htao_valueForKey:@"STTabProxy"];
}


+ (STTabProxy*)tabProxyForTabViewItem:(id)item
{
    return [item htao_valueForKey:@"STTabProxy"];
}


- (id)initWithTabViewItem:(id)item
{
    self = [super init];
    if (!self) return nil;
    
    
    _ownRef=(uintptr_t)(self);

    // Initialization code here.
    [item htao_setValue:self forKey:@"STTabProxy"];
    _cachedDomain=nil;
    _tabViewItem=item;
    _cachedImage=nil;
    _isLoading=NO;
    _waitIcon=NO;
    _isMarked=NO;
    _isUnread=NO;
    _isInAnyWidget=NO;
    _invalid=NO;
    _hidden=NO;
    _creationDate=[NSDate date];
    _modificationDate=_creationDate;

    [[STTabProxyController si]addTabProxy:self];
    self.title=[item title];
    //まだwindowに入ってない
    [[NSNotificationCenter defaultCenter]postNotificationName:STTabProxyCreatedNote object:self];

    
    return self;
}


- (void)tabViewItemWillDealloc
{
    LOG(@"STTabProxy will dealloc");
    _invalid=YES;
    _tabViewItem=nil;
}


- (void)dealloc
{
    LOG(@"STTabProxy dealloc");
}


- (id)window
{
    id winCtl=STSafariBrowserWindowControllerForWKView([self wkView]);
    return [winCtl window];
}


- (id)wkView
{
    if (_invalid) return nil;
    
    return STSafariWKViewForTabViewItem(_tabViewItem);
}


- (void*)pageRef
{
    if (_invalid) return nil;

    return (void*)htWKPageRefForWKView([self wkView]);
}


- (BOOL)canClose
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


- (BOOL)isThereOtherTab
{
    if([[_tabViewItem tabView]numberOfTabViewItems]>1)return YES;
    
    return NO;
}


- (BOOL)isInPrivateBrowsing
{
    BOOL result=NO;
    id wkView=[self wkView];
    if ([wkView respondsToSelector:@selector(usesPrivateBrowsing)]) {
        result=((BOOL(*)(id, SEL, ...))objc_msgSend)(wkView, @selector(usesPrivateBrowsing));
    }
    
    return result;
}


- (NSString*)domain
{
    if (_invalid) return nil;
    if (!_cachedDomain) {
        _cachedDomain=HTDomainFromHost(_host);
    }
    return _cachedDomain;
}


- (NSString*)URLString
{
    if (_invalid) return nil;
    return [_tabViewItem URLString];
}


-(NSString*)imagePathForExt:(NSString*)ext
{
    if (_invalid) return nil;
    return STSafariThumbnailForURLString([self URLString], ext);
}


- (NSImage*)image
{
    return self.cachedImage;
}


- (NSImage*)icon
{
    return self.cachedImage;
}


- (NSTabView *)tabView
{
    if (_invalid) return nil;
    return [_tabViewItem tabView];
}


- (void)selectTab
{
    if(_invalid||[_tabViewItem tabState]==NSSelectedTab)return;
    
    id ctl=STSafariBrowserWindowControllerForWKView([self wkView]);

    //Safari 7
    if ([ctl respondsToSelector:@selector(_selectTab:)]) {
        objc_msgSend(ctl, @selector(_selectTab:), _tabViewItem);
    }
    
    //[[tabViewItem tabView]selectTabViewItem:tabViewItem];
}


#pragma mark - pageLoader


- (void)wkViewDidReplaced:(id)wkView
{
    if (_invalid) return;
    LOG(@"didReplaceWKView");
    
    //clean up for didStartProgress fail
    [self willChangeValueForKey:@"image"];
    self.cachedImage=nil;
    [self didChangeValueForKey:@"image"];
    _waitIcon=YES;
    
    //読み込み済みのwkViewだった場合favicon更新しないと表示されない
}


- (void)didStartProgress
{
    LOG(@"didStartProgress");
    
    self.isLoading=YES;
    
    [self willChangeValueForKey:@"image"];
    self.cachedImage=nil;
    [self didChangeValueForKey:@"image"];
    _waitIcon=YES;
    
    //self.domain=@"";
    
}

- (void)didFinishProgress
{
    LOG(@"didFinishProgress");

    
    self.isLoading=NO;
    self.modificationDate=[NSDate date];
    if([_tabViewItem tabState]!=NSSelectedTab)self.isUnread=YES;

    
    self.title=[self.tabViewItem title];
    self.host=[[NSURL URLWithString:[self URLString]]host];
    _cachedDomain=nil;

    if (_waitIcon && [self.host length]>0) {
        if (![self fetchIconImage]) {
            //clean up for didStartProgress fail
            [self willChangeValueForKey:@"image"];
            self.cachedImage=nil;
            [self didChangeValueForKey:@"image"];
        }
    }
    
    [[NSNotificationCenter defaultCenter]postNotificationName:STTabProxyDidFinishProgressNote object:self];
}


- (void)iconDatabaseDidAddIconForURL:(NSURL*)url
{
    if (_invalid || !_waitIcon) {
        return;
    }
    NSString* updatedURLString=[url absoluteString];
    NSString* currentURLString=self.URLString;
    if ([updatedURLString isEqualToString:currentURLString]) {
        LOG(@"iconDatabaseDidAddIcon");
        [self fetchIconImage];
    }
}


- (void)installedToSidebar:(id)ctl
{
    self.isInAnyWidget=YES;
}

//This method may be called after target tab has closed.
- (void)uninstalledFromSidebar:(id)ctl
{
    self.isInAnyWidget=NO;
}

- (BOOL)fetchIconImage
{
    if (_invalid) {
        return YES;
    }
    
    if (!self.host) {
        return NO;
    }
    
    id wkView=self.wkView;
    if (wkView) {
        NSImage* icon=htWKIconImageForWKView(wkView, 32.0);
        if (icon) {
            [self willChangeValueForKey:@"image"];
            self.cachedImage=icon;
            [self didChangeValueForKey:@"image"];
            _waitIcon=NO;
            return YES;
        }
    }
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
    if (_invalid||![self isThereOtherTab]) return;
    
    
    //BrowserWindowControllerMac - (void)tryToCloseOtherTabsWhenReady:(NSTabViewItem*)arg1;
    id winCtl=STSafariBrowserWindowControllerForWKView([self wkView]);
    if ([winCtl respondsToSelector:@selector(tryToCloseOtherTabsWhenReady:)]) {
        objc_msgSend(winCtl, @selector(tryToCloseOtherTabsWhenReady:), _tabViewItem);
    }
}


- (IBAction)actReload:(id)sender
{
    if (_invalid) return;
    STSafariReloadTab(self.tabViewItem);
}


- (IBAction)actMoveTabToNewWindow:(id)sender
{
    if (_invalid||![self isThereOtherTab]) return;
    STSafariMoveTabToNewWindow(self.tabViewItem);
}


@end

