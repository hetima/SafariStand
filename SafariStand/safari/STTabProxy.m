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
//#import <WebKit2/WKImage.h>
//#import <WebKit2/WKImageCG.h>
//#import <WebKit2/WKBundlePage.h>

#import "HTWebKit2Adapter.h"


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
    return [STTabViewItemForWKView(wkView) htaoValueForKey:@"STTabProxy"];
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
//        [self release];
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
    id winCtl=STBrowserWindowControllerMacForWKView([self wkView]);
    return [winCtl window];
    //return [[tabViewItem view]window];
}

- (id)wkView
{
    return STWKViewForTabViewItem(_tabViewItem);
}

-(BOOL)canClose{
    if([[_tabViewItem tabView]numberOfTabViewItems]>1)return YES;
    return NO;
    /*
    if ([tabViewItem respondsToSelector:@selector(canBeClosed)]) {
        return (BOOL)objc_msgSend(tabViewItem, @selector(canBeClosed));
    }
    return NO;
     */
}
-(BOOL)isThereOtherTab{
    if([[_tabViewItem tabView]numberOfTabViewItems]>1)return YES;
    
    return NO;
}


/*
- (NSString*)title
{
    return [tabViewItem title];
}*/

- (NSString*)URLString
{
    return [_tabViewItem URLString];
}

-(NSString*)imagePathForExt:(NSString*)ext
{
    return STThumbnailForURLString([self URLString], ext);

}

- (void)updateImage
{
    if (self.isLoading|| !self.wantsImage)return;
/*    NSString* currentURLString=[self URLString];
    
    if (![currentURLString isEqualToString:_cachedImageURLString] || !self.cachedImage) {
        NSImage* icn=htWKIconImageForURLString(currentURLString, (WKPageRef)[[self wkView]pageRef]);
        [self willChangeValueForKey:@"icon"];
        self.cachedImage=icn;
        [self didChangeValueForKey:@"icon"];
    }
*/
    /*
    //WKPagePrivate.h
    extern WKImageRef WKPageCreateSnapshotOfVisibleContent(WKPageRef page);
    
    WKView* pView=[self wkView];
    WKPageRef pRef=[pView pageRef];
    WKImageRef wkImgRef=WKPageCreateSnapshotOfVisibleContent(pRef);
    CGImageRef imageRef=WKImageCreateCGImage(wkImgRef);
    NSImage* srcImg = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];

    //縮小
    NSSize imgSize=NSMakeSize(480, 380);
    NSSize srcSize=[srcImg size];
    
    NSRect srcRect=NSMakeRect(0,0,srcSize.width,srcSize.height);
    srcRect.size.height=(srcSize.width/imgSize.width)*imgSize.height;

    if(![srcImg isFlipped])
        srcRect.origin.y=srcSize.height-srcRect.size.height;

    NSImage* img=[[[NSImage alloc]initWithSize:imgSize]autorelease];
    //            [img setFlipped:YES];
    [img setScalesWhenResized:YES];
    
    [img lockFocus];
    [[NSGraphicsContext currentContext]saveGraphicsState];
    [[NSGraphicsContext currentContext]setImageInterpolation:NSImageInterpolationMedium];
    
    [srcImg drawInRect:NSMakeRect(0,0,imgSize.width,imgSize.height)
               fromRect:srcRect
              operation:NSCompositeCopy fraction:1.0];
    
    [[NSGraphicsContext currentContext]restoreGraphicsState];
    [img unlockFocus];
    
    [srcImg release];
    CGImageRelease(imageRef);
    WKRelease(wkImgRef);
    
    [self willChangeValueForKey:@"image"];
    self.cachedImage=img;
    [self didChangeValueForKey:@"image"];
    
    */
    
}

#define kWebViewThumbDefaultWidth 320
#define kWebViewThumbMaxWidth 1024
//#define kWebViewThumbHeightRatio 4.5
//#define kWebViewThumbPadding 6
//#define kWebViewThumbPaddingBottom 18
- (NSImage*)makeImage
{
    NSImage* img=nil;
	NSView* pView=nil;
	NSImage* tempImg=nil;
	NSSize  thumbSize;
    
    CGFloat dfWidth=kWebViewThumbDefaultWidth;
    //[[self window]disableCursorRects];
    //[[self window]disableFlushWindow];
    //    [[self window]disableScreenUpdatesUntilFlush];
    pView=[self wkView];
	if(pView){//WebHTMLView
		//サイズ計算
        //CGFloat scaleX=1.0;
        CGFloat scaleY=0.5;
        
		NSSize imgSize=[pView frame].size;
        //if(pView==self && imgSize.width>20)imgSize.width-=16;//スクロールバー除外
        CGFloat disHeight=floor(imgSize.width*scaleY); //比率で掛けて縮小 width基準
		if(imgSize.height > disHeight)imgSize.height=disHeight;
        
        NSRect clipRect=[pView frame];
        
        if(![pView isFlipped])
            clipRect.origin.y=clipRect.size.height-imgSize.height;
        
        clipRect.size=imgSize;
        
        //イメージ生成
        tempImg=[[NSImage alloc]initWithSize:imgSize];
        [tempImg setScalesWhenResized:YES];
        [tempImg setFlipped:YES];
        [tempImg lockFocus];
        [pView drawRect:NSMakeRect(0,0,[tempImg size].width,[tempImg size].height)];
        [tempImg unlockFocus];
		
		if(tempImg){
            //比率で掛けて縮小
            thumbSize.height=floorf(imgSize.height/(imgSize.width/dfWidth));
            thumbSize.width=dfWidth;
            img=[[NSImage alloc]initWithSize:thumbSize];
            //            [img setFlipped:YES];
            [img setScalesWhenResized:YES];
            
            [img lockFocus];
            [[NSGraphicsContext currentContext]saveGraphicsState];
            [[NSGraphicsContext currentContext]setImageInterpolation:NSImageInterpolationHigh];
            //[tempImg draw];
            
            [tempImg drawInRect:NSMakeRect(0,0,thumbSize.width,thumbSize.height)
                       fromRect:NSMakeRect(0,0,imgSize.width,imgSize.height)
                      operation:NSCompositeCopy fraction:1.0];
            
            [[NSGraphicsContext currentContext]restoreGraphicsState];
            [img unlockFocus];
		}
	}
    //[[self window]enableFlushWindow];
    //[[self window]enableCursorRects];
	return img;
    
    
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
    
    id ctl=STBrowserWindowControllerMacForWKView([self wkView]);
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

    if (self.wantsImage) {
        //これまでの予約をキャンセル
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(updateImage) object:nil];
        //新しい予約を入れる
        [self performSelector:@selector(updateImage) withObject:nil afterDelay:0.2];        
    }
    
    
}
/*-(void)didFinishLoadForFrame{
    LOG(@"didFinishLoadForFrame");
}*/

- (IBAction)actClose:(id)sender
{
    if (invalid) return; //連続呼び出し対策
    
    id winCtl=STBrowserWindowControllerMacForWKView([self wkView]);
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
    id winCtl=STBrowserWindowControllerMacForWKView([self wkView]);
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

#pragma mark - IKImageBrowserItem Protocol

- (NSString *)  imageUID
{
    return HTMD5StringFromString([self URLString]);
}

- (NSString *) imageRepresentationType
{
    return IKImageBrowserNSImageRepresentationType;
}

- (id) imageRepresentation
{
    return [self image];
}

- (NSUInteger) imageVersion
{
    return 1;
}

- (NSString *) imageTitle
{
    return [self title];
}

- (NSString *) imageSubtitle
{
    return [self URLString];
}

- (BOOL) isSelectable
{
    return YES;
}

-(void)installedToSidebar:(id)ctl
{
    
    if (ctl) {
        self.wantsImage=YES;
        //新しい予約を入れる
        [self performSelector:@selector(updateImage) withObject:nil afterDelay:0.2];        
    }else{
        self.wantsImage=NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(updateImage) object:nil];
        self.cachedImage=nil;
    }
}

#pragma mark - frame


@end
