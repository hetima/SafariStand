//
//  STTabProxy.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import "STTabProxy.h"
#import <Quartz/Quartz.h>
//#import <WebKit2/WKImage.h>
//#import <WebKit2/WKImageCG.h>
//#import <WebKit2/WKBundlePage.h>

#import "HTWebKit2Adapter.h"


@implementation STTabProxyController
@synthesize allTabProxy;


static STTabProxyController *sharedInstance;

//tabの数変更を監視する
static void (*orig_tabViewDidChangeNum)(id, SEL, ...); //TabBarView tabViewDidChangeNumberOfTabViewItems:
static void ST_tabViewDidChangeNum(id self, SEL _cmd, id obj)
{
	orig_tabViewDidChangeNum(self,_cmd, obj);
	[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidChangeNote object:obj];
}

//tabの選択を監視する
static void (*orig_tabViewDidSelectItem)(id, SEL, ...); //TabBarView tabView:didSelectTabViewItem:
static void ST_tabViewDidSelectItem(id self, SEL _cmd, id obj, id item)
{
	orig_tabViewDidSelectItem(self,_cmd, obj, item);
    STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:item];
    proxy.isUnread=NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidSelectItemNote object:obj];
}

//- (void)replaceTabView:(id)arg1;
//tabView入れ替わりを監視
static void (*orig_replaceTabView)(id, SEL, ...);
static void ST_replaceTabView(id self, SEL _cmd, id obj)
{
    orig_replaceTabView(self, _cmd, obj);
    [[STTabProxyController si]maintainTabSelectionOrder:[STTabProxy tabProxyForTabViewItem:obj]];
	[[NSNotificationCenter defaultCenter] postNotificationName:STTabViewDidChangeNote object:obj];
    
}

//tabViewItem を生成するとき STTabProxy を付ける
static id (*orig_initWithTabBarView)(id, SEL, ...);
static id ST_initWithTabBarView(id self, SEL _cmd, id tabBarView, BOOL useWebKit2, void* tab)
{
    id result=orig_initWithTabBarView(self, _cmd, tabBarView, useWebKit2, tab);
    if(useWebKit2){
        id proxy __unused=[[STTabProxy alloc]initWithTabViewItem:result];
    }
    return result;
}

//tabViewItem が取り除かれるとき STTabProxyリストから除外
static void (*orig_removeTabViewItem)(id, SEL, ...);
static void ST_removeTabViewItem(id self, SEL _cmd, id tabViewItem)
{
    id proxy=[STTabProxy tabProxyForTabViewItem:tabViewItem];
    if(proxy){
        [NSObject cancelPreviousPerformRequestsWithTarget:proxy
                                                 selector:@selector(updateImage) object:nil];

        [[STTabProxyController si]removeTabProxy:proxy];
    }
    orig_removeTabViewItem(self, _cmd, tabViewItem);
}


//tabViewItem がdealloc、 STTabProxyリストから除外
static void (*orig_tabViewItem_dealloc)(id, SEL);
//重要：dealloc 中 retain されないように self は __unsafe_unretained
static void ST_tabViewItem_dealloc(__unsafe_unretained id self, SEL _cmd)
{
    id proxy=[STTabProxy tabProxyForTabViewItem:self];
    if(proxy){
        [NSObject cancelPreviousPerformRequestsWithTarget:proxy
                                                 selector:@selector(updateImage) object:nil];
        
        [[STTabProxyController si]removeTabProxy:proxy];
    }
    orig_tabViewItem_dealloc(self, _cmd);
}



//STTabProxy の title を更新
static void (*orig_setLabel)(id, SEL, ...);
static void ST_setLabel(id self, SEL _cmd, NSString* label)
{
    orig_setLabel(self, _cmd, label);

    STTabProxy* proxy=[STTabProxy tabProxyForTabViewItem:self];
    proxy.title=label;
}


- (void)setup
{
    NSMutableArray* ary=[[NSMutableArray alloc]initWithCapacity:32];
    self.allTabProxy=ary;

    //既存のものにパッチ
    NSArray* windows=[NSApp windows];
    for (NSWindow* win in windows) {
        id winCtl=[win windowController];
        if([[winCtl className]isEqualToString:kSafariBrowserWindowController]
           && [winCtl respondsToSelector:@selector(orderedTabViewItems)]){
            NSArray* tabs=objc_msgSend(winCtl, @selector(orderedTabViewItems));
            for (id tabViewItem in tabs) {
                //if ([tabViewItem respondsToSelector:@selector(usesWebKit2)] && objc_msgSend(tabViewItem, @selector(usesWebKit2))) {
                    id proxy __unused=[[STTabProxy alloc]initWithTabViewItem:tabViewItem];
                //}
            }
        }
    }
    

    //tabViewItem を生成するとき STTabProxy を付ける
    orig_initWithTabBarView = (id(*)(id, SEL, ...))RMF(NSClassFromString(@"BrowserTabViewItem"),
                                @selector(initWithTabBarView:useWebKit2:withBrowserTab:), ST_initWithTabBarView);

    //tabの数変更を監視するため
    orig_tabViewDidChangeNum = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"TabBarView"),
                                @selector(tabViewDidChangeNumberOfTabViewItems:), ST_tabViewDidChangeNum);
    //tabの選択を監視するため
    orig_tabViewDidSelectItem = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"TabBarView"),
                                @selector(tabView:didSelectTabViewItem:), ST_tabViewDidSelectItem);

    //tabView入れ替わりを監視するため
    orig_replaceTabView = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"TabBarView"),
                                @selector(replaceTabView:), ST_replaceTabView);

    
    //STTabProxy の title を更新するため
    orig_setLabel = (void(*)(id, SEL, ...))RMF(NSClassFromString(@"BrowserTabViewItem"),
                                @selector(setLabel:), ST_setLabel);
    
    //STTabProxyをリストから除外するため
//    orig_removeTabViewItem = RMF(NSClassFromString(kSafariBrowserWindowController),
//                              @selector(_removeTabViewItem:), ST_removeTabViewItem);
    orig_tabViewItem_dealloc = (void(*)(id, SEL))RMF(NSClassFromString(@"BrowserTabViewItem"),
                                NSSelectorFromString(@"dealloc"), ST_tabViewItem_dealloc);

}

+ (STTabProxyController *)si
{
    if (sharedInstance == nil) {
		sharedInstance = [[STTabProxyController alloc]init];
        [sharedInstance setup];
    }
    
    return sharedInstance;
}

+ (NSMutableArray *)tabProxiesForTabView:(NSTabView*)tabView{
    NSMutableArray* ary=nil;
    NSArray* tabs=[tabView tabViewItems];
    ary=[NSMutableArray arrayWithCapacity:[tabs count]];
    for (id tabViewItem in tabs) {
        if ([tabViewItem respondsToSelector:@selector(usesWebKit2)] && objc_msgSend(tabViewItem, @selector(usesWebKit2))) {
            id proxy=[STTabProxy tabProxyForTabViewItem:tabViewItem];
            if (proxy) {
                [ary addObject:proxy];
            }
        }
    }
    return ary;

}

+ (NSMutableArray *)tabProxiesForWindow:(NSWindow*)win
{
    NSMutableArray* ary=nil;
    id winCtl=[win windowController];
    if([[winCtl className]isEqualToString:kSafariBrowserWindowController]
       && [winCtl respondsToSelector:@selector(orderedTabViewItems)]){
        NSArray* tabs=objc_msgSend(winCtl, @selector(orderedTabViewItems));
        
        ary=[NSMutableArray arrayWithCapacity:[tabs count]];
        for (id tabViewItem in tabs) {
            if ([tabViewItem respondsToSelector:@selector(usesWebKit2)] && objc_msgSend(tabViewItem, @selector(usesWebKit2))) {
                id proxy=[STTabProxy tabProxyForTabViewItem:tabViewItem];
                if (proxy) {
                    [ary addObject:proxy];
                }
            }
        }
    }
    return ary;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void)addTabProxy:(id)tabProxy
{
    [self.allTabProxy addObject:tabProxy];
}

- (void)removeTabProxy:(id)tabProxy
{
    NSInteger idx=[self.allTabProxy indexOfObjectIdenticalTo:tabProxy];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"tabProxyWillRemove" object:tabProxy];
    if (idx!=NSNotFound) {
        [self.allTabProxy removeObjectAtIndex:idx];
    }
    
}

-(void)maintainTabSelectionOrder:(id)tabProxy
{
    if (tabProxy) {
        [self.allTabProxy removeObject:tabProxy];
        [self.allTabProxy addObject:tabProxy];
    }
}

-(NSTabViewItem*)lastSelectedTabViewItemForwindow:(NSWindow*)win
{
    NSTabViewItem* result=nil;
    NSEnumerator* e=[self.allTabProxy reverseObjectEnumerator];
    STTabProxy* tabProxy=nil;
    while (tabProxy=[e nextObject]) {
        if ([[tabProxy tabView]window]==win) {
            result=[tabProxy tabViewItem];
            break;
        }
    }
    return result;
}

@end


@implementation STTabProxy
{
    BOOL invalid;
    
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

- (IBAction)actClose:(id)sender {
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
- (IBAction)actCloseOther:(id)sender {
    if (![self isThereOtherTab]||invalid) return;
    
    
    //BrowserWindowControllerMac - (void)tryToCloseOtherTabsWhenReady:(NSTabViewItem*)arg1;
    id winCtl=STBrowserWindowControllerMacForWKView([self wkView]);
    if ([winCtl respondsToSelector:@selector(tryToCloseOtherTabsWhenReady:)]) {
        objc_msgSend(winCtl, @selector(tryToCloseOtherTabsWhenReady:), _tabViewItem);
    }
}

- (IBAction)actReload:(id)sender {
    STSafariReloadTab(self.tabViewItem);
}

- (IBAction)actMoveTabToNewWindow:(id)sender {
    if (![self isThereOtherTab]||invalid) return;
    STSafariMoveTabToNewWindow(self.tabViewItem);
}

#pragma mark - IKImageBrowserItem Protocol
- (NSString *)  imageUID{
    return HTMD5StringFromString([self URLString]);
}
- (NSString *) imageRepresentationType{
    return IKImageBrowserNSImageRepresentationType;
}

- (id) imageRepresentation{
    return [self image];
}

- (NSUInteger) imageVersion{
    return 1;
}

- (NSString *) imageTitle{
    return [self title];
}

- (NSString *) imageSubtitle{
    return [self URLString];
}


- (BOOL) isSelectable{
    return YES;
}

-(void)installedToSidebar:(id)ctl{
    
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
