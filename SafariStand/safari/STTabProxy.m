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
#import "STPreviewImageManager.h"

@implementation STTabProxy
{
    BOOL invalid;
}

- (void)goToURL:(NSURL*)urlToGo
{
    htWKGoToURL([self wkView], urlToGo);
}

+(STTabProxy*)tabProxyForWKView:(id)wkView
{
    return [STSafariTabViewItemForWKView(wkView) htaoValueForKey:@"STTabProxy"];
}

+(STTabProxy*)tabProxyForTabViewItem:(id)item
{
    return [item htaoValueForKey:@"STTabProxy"];
}


- (id)initWithTabViewItem:(id)item
{
    self = [super init];
    if (self) {
        _ownRef=(uintptr_t)(self);

        // Initialization code here.
        [item htaoSetValue:self forKey:@"STTabProxy"];
        self.tabViewItem=item;
        self.cachedImage=nil;
        self.isLoading=NO;
        self.wantsImage=NO;
        self.isMarked=NO;
        self.isUnread=NO;
        invalid=NO;

        [[STTabProxyController si]addTabProxy:self];
        self.title=[item title];
        //まだwindowに入ってない
        [[NSNotificationCenter defaultCenter]postNotificationName:STTabProxyCreatedNote object:self];
    }
    
    return self;
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
    return STSafariWKViewForTabViewItem(_tabViewItem);
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

- (void)previewImageDelivered:(STPreviewImageDelivery*)delivery
{
    NSImage* image=delivery.image;
    if (!image) {
        NSString* imagePath=delivery.path;
        image=[[NSImage alloc]initByReferencingFile:imagePath];
    }
    [self willChangeValueForKey:@"image"];
    self.cachedImage=image;
    [self didChangeValueForKey:@"image"];
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
    if ([ctl respondsToSelector:@selector(_showTab:)]) {
        objc_msgSend(ctl, @selector(_showTab:), _tabViewItem);
    }
    //[[tabViewItem tabView]selectTabViewItem:tabViewItem];
}


#pragma mark - pageLoader

-(void)didStartProgress
{
    LOG(@"didStartProgress");
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

    if (self.wantsImage && [self.domain length]>0) {
        [[[STTabProxyController si]previewImageManager]requestPreviewImage:self instantDelivery:NO];
    }
}

-(void)installedToSidebar:(id)ctl
{
    if (!self.wantsImage) {
        self.wantsImage=YES;
        [[[STTabProxyController si]previewImageManager]requestPreviewImage:self instantDelivery:YES];
    }
}

//This method may be called after target tab has closed.
-(void)uninstalledFromSidebar:(id)ctl
{
    if (self.wantsImage) {
        self.wantsImage=NO;
        self.cachedImage=nil;
    }
}

#pragma mark - IBAction

- (IBAction)actClose:(id)sender
{
    if (invalid) return; //連続呼び出し対策
    
    id winCtl=STSafariBrowserWindowControllerForWKView([self wkView]);
    if (![self canClose]) {
        [[winCtl window]performClose:nil];
    }else{
        //BrowserWindowControllerMac - (void)tryToCloseTabWhenReady:(NSTabViewItem*)arg1;
        if ([winCtl respondsToSelector:@selector(tryToCloseTabWhenReady:)]) {
            invalid=YES;
            objc_msgSend(winCtl, @selector(tryToCloseTabWhenReady:), _tabViewItem);
        }
    }
    
}

- (IBAction)actCloseOther:(id)sender
{
    if (![self isThereOtherTab]||invalid) return;
    
    
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
    if (![self isThereOtherTab]||invalid) return;
    STSafariMoveTabToNewWindow(self.tabViewItem);
}


@end

