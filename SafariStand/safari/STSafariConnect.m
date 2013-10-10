//
//  STSafariConnect.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STSafariConnect.h"

#import <Carbon/Carbon.h>

struct TabPlacementHint {
    void* m_safariBrowserWindow;
    void* m_browserContentViewController;
    _Bool m_contentViewIsAncestorTab;
};



#pragma mark navigation

void STSafariGoToURL(NSURL* url){

    STSafariGoToURLWithPolicy(url, poNormal);
}

void STSafariGoToURLWithPolicy(NSURL* url, int policy)
{
    id sdc=[NSDocumentController sharedDocumentController];
    if([sdc respondsToSelector:@selector(goToURL:windowPolicy:)]){
        //result=struct BrowserContentViewController
        objc_msgSend(sdc, @selector(goToURL:windowPolicy:), url, policy);
    }
}

//no support poNewWindow
void STSafariGoToRequestWithPolicy(NSURLRequest* req, int policy)
{
    if(!req)return;
    
    id sdc=[NSDocumentController sharedDocumentController];
    
    struct TabPlacementHint tph={nil,nil,0};
    
    if([sdc respondsToSelector:@selector(goToRequest:tabLabel:windowPolicy:tabPlacementHint:frameName:)]){
        //- (struct BrowserContentViewController *)goToRequest:(id)arg1 tabLabel:(id)arg2 windowPolicy:(int)arg3 tabPlacementHint:(const struct TabPlacementHint *)arg4 frameName:(id)arg5;
        //result=struct BrowserContentViewController
        //id favoriteButton=[[NSClassFromString(@"FavoriteButton") alloc]initWithFrame:NSZeroRect];
        //tph=[favoriteButton _tabPlacementHint];
        //LOG(@"%d, %d, %d",tph.m_safariBrowserWindow,tph.m_browserContentViewController,tph.m_contentViewIsAncestorTab);
        //[favoriteButton release];
        objc_msgSend(sdc, @selector(goToRequest:tabLabel:windowPolicy:tabPlacementHint:frameName:), req, nil, policy, &tph, nil);
    }
    
    
    //_frontmostBrowserDocumentIfAvailableUsingWindowPolicy;
    //frontmostBrowserDocument
    //findOrCreateFrontmostBrowserDocument
    /*    BOOL needTab=NO;
    id doc;
    if(policy==poNewWindow||policy==poNewWindow_back){
        doc=objc_msgSend(sdc, @selector(createHiddenEmptyBrowserDocument));
    }

    if(policy==poNewTab||policy==poNewTab_back)needTab=YES;
    doc=objc_msgSend(sdc, @selector(frontmostBrowserDocument));
    if(!doc){
        doc=objc_msgSend(sdc, @selector(findOrCreateFrontmostBrowserDocument));
        needTab=NO;
    }
    if([doc respondsToSelector:@selector(goToRequest:withTabLabel:)]){
        objc_msgSend(doc, @selector(goToRequest:withTabLabel:), req, nil);
    }*/
}


NSString* STSafariDownloadDestinationWithFileName(NSString* fileName)
{
    NSFileManager* fm=[NSFileManager defaultManager];
    if (![fm respondsToSelector:@selector(_webkit_pathWithUniqueFilenameForPath:)])return nil;

    NSString* outDir=[[NSUserDefaults standardUserDefaults]stringForKey:@"DownloadsPath"];
    outDir=[outDir stringByStandardizingPath];
    outDir=[outDir stringByAppendingPathComponent:fileName];
    outDir=objc_msgSend(fm, @selector(_webkit_pathWithUniqueFilenameForPath:), outDir);


    return outDir;
}

void STSafariDownloadURL(NSURL* url)
{
    NSURLRequest *req=[NSURLRequest requestWithURL:url];
    STSafariDownloadRequest(req);
}
void STSafariDownloadRequest(NSURLRequest* req)
{
    Class dmClass=NSClassFromString(@"DownloadMonitorOld");
    if (![dmClass respondsToSelector:@selector(sharedDownloadMonitor)])return;

    id dm=objc_msgSend(dmClass, @selector(sharedDownloadMonitor));
    if(![dm respondsToSelector:@selector(startDownloadForRequest:mayOpenWhenDone:)])return;
    
    objc_msgSend(dm, @selector(startDownloadForRequest:mayOpenWhenDone:),req,NO);
}

void STSafariDownloadURLWithFileName(NSURL* url, NSString* fileName)
{
    NSURLRequest *req=[NSURLRequest requestWithURL:url];
    STSafariDownloadRequestWithFileName(req, fileName);

}
void STSafariDownloadRequestWithFileName(NSURLRequest* req, NSString* fileName)
{
    Class dmClass=NSClassFromString(@"DownloadMonitorOld");
    if (![dmClass respondsToSelector:@selector(sharedDownloadMonitor)])return;
    
    id dm=objc_msgSend(dmClass, @selector(sharedDownloadMonitor));
    if(![dm respondsToSelector:@selector(startDownloadForRequest:mayOpenWhenDone:allowOverwrite:path:)])return;
//    @selector(startDownloadForRequest:mayOpenWhenDone:allowOverwrite:path:)
    NSString* path=STSafariDownloadDestinationWithFileName(fileName);
LOG(@"%@",path);
    objc_msgSend(dm, @selector(startDownloadForRequest:mayOpenWhenDone:allowOverwrite:path:), req, NO, NO, path);
    
}


void STSafariNewTabAction(){
    
    [NSApp sendAction:@selector(newTab:) to:nil from:nil];
    

}

// -(BrowserContentViewController*)[BrowserWindowControllerMac createTabWithFrameName:atIndex:andShow:]
// と同じようにする
// return BrowserTabViewItem
id STSafariCreateWKViewOrWebViewAtIndexAndShow(NSWindow* win, NSInteger idx, BOOL show)
{
    id result=nil;
    id winCtl=[win windowController];
	if(![winCtl respondsToSelector:@selector(usesWebKit2)] ||
       ![winCtl respondsToSelector:@selector(browserDocument)] ||
       ![winCtl respondsToSelector:@selector(_createTabWithView:atIndex:andShow:)] 
       ){
        return nil;
    }

    id doc=objc_msgSend(winCtl, @selector(browserDocument));
    id webView=nil;
    
	if(objc_msgSend(winCtl, @selector(usesWebKit2))){
        if([doc respondsToSelector:@selector(createWKView)]){
            webView=objc_msgSend(doc, @selector(createWKView));
        }
	}else{
        if([doc respondsToSelector:@selector(createWebViewWithFrameName:)]){
            webView=objc_msgSend(doc, @selector(createWebViewWithFrameName:), nil);
        }
    }
    
    if (webView) {
        result=objc_msgSend(winCtl, @selector(_createTabWithView:atIndex:andShow:), webView, idx, show);
    }
    return result;
}

BOOL STSafariOpenNewTabsInFront(){
    return [[NSUserDefaults standardUserDefaults]boolForKey:@"OpenNewTabsInFront"];
}

int STSafariWindowPolicyNewTab(){
    if(STSafariOpenNewTabsInFront()) return poNewTab;
    else return poNewTab_back;
}

int STSafariWindowPolicyNewTabRespectingCurrentEvent(){
    int policy=STSafariWindowPolicyNewTab();

    //とりあえずShiftキーは無視で
    //int shiftCheck=0;
    //UInt32 carbonModFlag=GetCurrentEventKeyModifiers();
    //if(carbonModFlag & shiftKey/*||carbonModFlag & rightShiftKey*/)shiftCheck=1;
    //policy=policy ^ shiftCheck
    
    return policy;
}

int STSafariWindowPolicyFromCurrentEvent(){
    /*
     BrowserWindowControllerMac : WindowController
     + (int)windowPolicyFromEventModifierFlags:(unsigned int)arg1 isMiddleMouseButton:(BOOL)arg2 requireCommandKey:(BOOL)arg3;
     + (int)windowPolicyFromEventModifierFlags:(unsigned int)arg1 isMiddleMouseButton:(BOOL)arg2;
     + (int)windowPolicyFromEventModifierFlags:(unsigned int)arg1 requireCommandKey:(BOOL)arg2;
     + (int)windowPolicyFromCurrentEventRequireCommandKey:(BOOL)arg1;//NOだとcmdを押してなくても押しているものとみなす
     + (int)windowPolicyFromCurrentEvent;
     + (int)windowPolicyFromCurrentEventRespectingKeyEquivalents:(BOOL)arg1;
     + (int)windowPolicyFromNavigationAction:(const struct SWebNavigationAction *)arg1;
     
     */
    int policy=(int)objc_msgSend(NSClassFromString(kSafariBrowserWindowController),
                //@selector(windowPolicyFromCurrentEventRespectingKeyEquivalents:), YES);
                @selector(windowPolicyFromCurrentEventRequireCommandKey:), YES);
    return policy;
}

#pragma mark -
#pragma mark access
id STSafariCurrentDocument()
{
    NSDocument* doc=nil;
	id sdc=[NSDocumentController sharedDocumentController];
    if([sdc respondsToSelector:@selector(frontmostBrowserDocument)]){
        doc=objc_msgSend(sdc, @selector(frontmostBrowserDocument));
    }
    return doc;
}

NSWindow* STSafariCurrentBrowserWindow()
{
    NSView* view=STSafariCurrentWKView();
    return [view window];
}

id STSafariCurrentTitle()
{
    NSDocument* doc=STSafariCurrentDocument();
    return [doc displayName];
}

id STSafariCurrentURLString()
{
    NSString*   urlStr=nil;
    NSDocument* doc=STSafariCurrentDocument();
    if([doc respondsToSelector:@selector(URLString)]){
        urlStr=objc_msgSend(doc, @selector(URLString));
    }
    return urlStr;
}


id STSafariCurrentWKView()
{
    /*
     BrowserDocument.currentBrowserWebView
     BrowserDocument.currentBrowserOrOverlayWebView
     */

    id currentWebView=nil;
	NSDocument* doc=STSafariCurrentDocument();
	if([doc respondsToSelector:@selector(currentWKView)]){
        currentWebView=objc_msgSend(doc,@selector(currentWKView));
	}
    return currentWebView;
}

NSInteger STWindowSelectedTabIndex(NSWindow* win)
{
    id winCtl=[win windowController];
	if([winCtl respondsToSelector:@selector(selectedTabIndex)]){
        return (NSInteger)objc_msgSend(winCtl, @selector(selectedTabIndex));
	}
    return -1;
}

id STWKViewForTabViewItem(id tabViewItem)
{
	if([tabViewItem respondsToSelector:@selector(wkView)]){
        return objc_msgSend(tabViewItem, @selector(wkView));
	}
    return nil;
}

//
id STTabViewItemForWKView(id wkView)
{
    id winCtl=STBrowserWindowControllerMacForWKView(wkView);
    if([winCtl respondsToSelector:@selector(tabViewItemForWebView:)]){
        return objc_msgSend(winCtl, @selector(tabViewItemForWebView:), wkView);
    }
    return nil;
}

//STTabSwitcherForWinCtl() でもいいか
id/* NSTabView */ STTabViewForWindow(NSWindow* win)
{
    id result=nil;
    id winCtl=[win windowController];
    if([[winCtl className]isEqualToString:kSafariBrowserWindowController]
        && [winCtl respondsToSelector:@selector(selectedTab)]){
        id tabViewItem=objc_msgSend(winCtl, @selector(selectedTab));
        result=[tabViewItem tabView];
    }
    
    return result;
}

NSView* /* TabContentView */ STTabContentViewForTabView(NSView* tabView)
{
    NSArray* subviews=[tabView subviews];
    for (NSView* subview in subviews) {
        if ([[subview className]isEqualToString:@"TabContentView"]) {
            return subview;
        }
    }
    return nil;
}


//-(void)[BrowserWindowControllerMac moveTab:toIndex:]
void STMoveTabViewItemToIndex(id tabViewItem, NSInteger idx)
{
    NSWindow* win=[[tabViewItem tabView]window];
    id winCtl=[win windowController];
    if ([winCtl respondsToSelector:@selector(moveTab:toIndex:)]) {
        objc_msgSend(winCtl, @selector(moveTab:toIndex:), tabViewItem, idx);
    }
}

void STSafariMoveTabToNewWindow(NSTabViewItem* item)
{
    NSWindow* win=[[item tabView]window];
    id winCtl=[win windowController];
    if (item && [winCtl respondsToSelector:@selector(_moveTabToNewWindow:)]) {
        objc_msgSend(winCtl, @selector(_moveTabToNewWindow:), item);
    }
    
}

void STSafariMoveTabToOtherWindow(NSTabViewItem* itemToMove, NSWindow* destWindow, NSInteger destIndex, BOOL show)
{
    id winCtl=[destWindow windowController];

    if (winCtl && itemToMove && destIndex >= 0 && [winCtl respondsToSelector:@selector(moveTabFromOtherWindow:toIndex:andShow:)]) {
        NSDisableScreenUpdates();

        objc_msgSend(winCtl, @selector(moveTabFromOtherWindow:toIndex:andShow:), itemToMove, destIndex, show);

//like _moveTabToNewWindow:
 /*       id sdc=[NSDocumentController sharedDocumentController];
        id tempDoc=objc_msgSend(sdc, @selector(createHiddenEmptyBrowserDocument));
        id tempWinCtl=objc_msgSend(tempDoc, @selector(browserWindowControllerMac));
        objc_msgSend(tempWinCtl, @selector(replaceEmptyTabWithTabs:), [NSArray arrayWithObject:];)
        
        
        */
        NSEnableScreenUpdates();
    }
    
}

void STSafariReloadTab(NSTabViewItem* item)
{
    NSWindow* win=[[item tabView]window];
    id winCtl=[win windowController];
    if (item && [winCtl respondsToSelector:@selector(_reloadTab:)]) {
        objc_msgSend(winCtl, @selector(_reloadTab:), item);
    }
    
}

BOOL STSafariCanReloadTab(NSTabViewItem* item)
{
    NSWindow* win=[[item tabView]window];
    id winCtl=[win windowController];
    if (item && [winCtl respondsToSelector:@selector(canReloadTab:)]) {
        return (BOOL)objc_msgSend(winCtl, @selector(canReloadTab:), item);
    }
    return NO;
}

id STBrowserWindowControllerMacForWKView(id wkView)
{
    if ([wkView respondsToSelector:@selector(browserWindowControllerMac)]) {
        return objc_msgSend(wkView, @selector(browserWindowControllerMac));
    }
    return nil;    
}

/*
id STTabSwitcherForWinCtl(id winCtl){
    NSTabView* tabView=nil;
    //object_getInstanceVariable は ARC で使用不可
    object_getInstanceVariable(winCtl, "tabSwitcher", (__bridge void **)&tabView);
    return tabView;
}
*/

NSImage* STSafariBundleImageNamed(NSString* name)
{
    NSImage* result=nil;
    NSString* path=[[NSBundle mainBundle] pathForImageResource:name];
    if (path) {
        result=[[NSImage alloc]initByReferencingFile:path];
    }
    return result;
}

NSImage* STSafariBundleBookmarkImage()
{
    return STSafariBundleImageNamed(@"ToolbarBookmarksTemplate");
}

NSImage* STSafariBundleHistoryImage()
{
    return STSafariBundleImageNamed(@"ToolbarHistoryTemplate");
}

NSImage* STSafariBundleReadinglistmage()
{
    return STSafariBundleImageNamed(@"ReadingList-GlassesSmall");    
}

#pragma mark -
#pragma mark etc

NSString* STSafariWebpagePreviewsPath()
{
    NSString* path=[NSHomeDirectory() stringByStandardizingPath];
    path=[path stringByAppendingPathComponent:@"Library/Caches/com.apple.Safari/Webpage Previews"];
    return path;
}

NSString* STThumbnailForURLString(NSString* URLString, NSString* ext)
{
    if ([ext isEqualToString:@"jpg"]) {
        ext=@"jpeg";
    }else if (![ext isEqualToString:@"jpeg"]) {
        ext=@"png";
    }
    NSString* md5Str=HTMD5StringFromString(URLString);
    
    NSString* path=STSafariWebpagePreviewsPath();
    NSString* name=[NSString stringWithFormat:@"%@.%@", md5Str, ext];
    path=[path stringByAppendingPathComponent:name];
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        return path;
    }
    return nil;
}


void STAddSearchStringHistory(NSString* str){
    id webSearchFieldCell=NSClassFromString(@"WebSearchFieldCell");
    if([webSearchFieldCell respondsToSelector:@selector(addSearchString:)]){
        objc_msgSend(webSearchFieldCell, @selector(addSearchString:), str);
    }

    NSString* kwd=str;
    NSRange aRange=[str rangeOfString:@" "];
    if(aRange.location!=NSNotFound){
        kwd=[str substringToIndex:aRange.location];
    }
    if([kwd length]){
        NSPasteboard*pb=[NSPasteboard pasteboardWithName:NSFindPboard];
        [pb clearContents];
        [pb setString:kwd forType:NSStringPboardType];
    }
    

}




int STWebBookmarkType(id webBookmark)
{
    if([webBookmark respondsToSelector:@selector(bookmarkType)]){
        int safariType=(int)objc_msgSend(webBookmark, @selector(bookmarkType));
        if(safariType==0)return wbBookmark;
        if(safariType==1)return wbFolder;
    }
    return wbInvalid;
}

NSString* STWebBookmarkURLString(id webBookmark)
{
    if([webBookmark respondsToSelector:@selector(URLString)]){
        return objc_msgSend(webBookmark, @selector(URLString));
    }
    return nil;
}
NSString* STWebBookmarkTitle(id webBookmark)
{
    if([webBookmark respondsToSelector:@selector(title)]){
        return objc_msgSend(webBookmark, @selector(title));
    }
    return nil;
}

@implementation STSafariConnect

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void)dealloc
{

}

@end
