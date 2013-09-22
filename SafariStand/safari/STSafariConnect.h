//
//  STSafariConnect.h
//  SafariStand


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

//飛ぶ
//0==普通 1==普通うしろ
//2==新規ウィンドウ  5==新規ウィンドウうしろ
//4==tab 5==tabうしろ

enum safariWindowPolicy{
    poNormal=0, //000
    poNormal_back=1, //001
    poNewWindow=2, //010
    poNewWindow_back=3, //011
    poNewTab=4, //100
    poNewTab_back=5 //101
};

enum webbookmarktype {
    wbInvalid = -1,
    wbBookmark = 0,
    wbFolder = 1
};

#define kSafariBrowserWindowController @"BrowserWindowControllerMac"

NSString* STThumbnailForURLString(NSString* URLString, NSString* ext);

BOOL STSafariOpenNewTabsInFront();
int STSafariWindowPolicyNewTab();
int STSafariWindowPolicyNewTabRespectingCurrentEvent();
int STSafariWindowPolicyFromCurrentEvent();

void STSafariGoToURL(NSURL* url);
void STSafariGoToURLWithPolicy(NSURL* url, int policy);
void STSafariGoToRequestWithPolicy(NSURLRequest* req, int policy);

NSString* STSafariDownloadDestinationWithFileName(NSString* fileName);
void STSafariDownloadURL(NSURL* url);
void STSafariDownloadRequest(NSURLRequest* req);
void STSafariDownloadURLWithFileName(NSURL* url, NSString* fileName);
void STSafariDownloadRequestWithFileName(NSURLRequest* req, NSString* fileName);


void STSafariNewTabAction();
id STSafariCreateWKViewOrWebViewAtIndexAndShow(NSWindow* win, NSInteger idx, BOOL show);

id STSafariCurrentDocument();
NSWindow* STSafariCurrentBrowserWindow();
id STSafariCurrentTitle();
id STSafariCurrentURLString();
id STSafariCurrentWKView();
id STWKViewForTabViewItem(id tabViewItem);
id STTabViewItemForWKView(id wkView);
id STTabViewForWindow(NSWindow* win);

void STMoveTabViewItemToIndex(id tabViewItem, NSInteger idx);
void STSafariMoveTabToNewWindow(NSTabViewItem* item);
void STSafariMoveTabFromOtherWindow(NSWindow* win, NSTabViewItem* item, NSInteger idx, BOOL show);
void STSafariReloadTab(NSTabViewItem* item);
BOOL STSafariCanReloadTab(NSTabViewItem* item);

id STBrowserWindowControllerMacForWKView(id wkView);
//id STTabSwitcherForWinCtl(id winCtl);

NSInteger STWindowSelectedTabIndex(NSWindow* win);

NSImage* STSafariBundleImageNamed(NSString* name);
NSImage* STSafariBundleBookmarkImage();
NSImage* STSafariBundleHistoryImage();
NSImage* STSafariBundleReadinglistmage();

//WebBookmark, WebBookmarkLeaf

void STAddSearchStringHistory(NSString* str);

int STWebBookmarkType(id webBookmark);
NSString* STWebBookmarkURLString(id webBookmark);
NSString* STWebBookmarkTitle(id webBookmark);






@interface STSafariConnect : NSObject {
@private
    
}

@end
