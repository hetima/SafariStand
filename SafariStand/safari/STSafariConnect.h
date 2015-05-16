//
//  STSafariConnect.h
//  SafariStand


@import AppKit;
@import WebKit;


//飛ぶ
//0==普通 1==普通うしろ
//2==新規ウィンドウ  5==新規ウィンドウうしろ
//4==tab 5==tabうしろ

//8.0
//0==普通 1==普通うしろ？
//2==新規ウィンドウ
//3==プライベートウィンドウ
//4==新規ウィンドウうしろ
//5==tab前
//6==tabうしろ


enum safariWindowPolicy {
    poNormal=0, //000
    poNormal_back=1, //001
    poNewWindow=2, //010
    poNewWindow_back=4, //011
    poNewTab=5, //100
    poNewTab_back=6, //101
    poNewPrivateWindow=3
};

enum webbookmarktype {
    wbInvalid = -1,
    wbBookmark = 0,
    wbFolder = 1
};

#define kSafariBrowserWindowController @"BrowserWindowControllerMac"
#define kSafariBrowserWindowControllerCstr "BrowserWindowControllerMac"

#define kSafariURLWindowPolicyDecider @"URLWindowPolicyDecider" //Safari 8

/*

STSafariEnumerateBrowserWindow(^(NSWindow* win, NSWindowController* winCtl, BOOL* stop){
    *stop=YES;
});

 */
void STSafariEnumerateBrowserWindow( void(^blk)(NSWindow* window, NSWindowController* winCtl, BOOL* stop) );

/*

STSafariEnumerateBrowserTabViewItem(^(NSTabViewItem* tabViewItem, BOOL* stop){
    *stop=YES;
});
 
 */
void STSafariEnumerateBrowserTabViewItem( void(^blk)(NSTabViewItem* tabViewItem, BOOL* stop) );



NSString* STSafariWebpagePreviewsPath();
NSString* STSafariThumbnailForURLString(NSString* URLString, NSString* ext);

BOOL STSafariOpenNewTabsInFront();
int STSafariWindowPolicyNewTab();
int STSafariWindowPolicyNewTabRespectingCurrentEvent();
int STSafariWindowPolicyFromCurrentEvent();

void STSafariGoToURL(NSURL* url);
void STSafariGoToURLWithPolicy(NSURL* url, int policy);
void STSafariGoToRequestWithPolicy(NSURLRequest* req, int policy);

NSString* STSafariDownloadDestinationWithFileName(NSString* fileName);
void STSafariDownloadURL(NSURL* url, BOOL removeEntryWhenDone);
void STSafariDownloadRequest(NSURLRequest* req, BOOL removeEntryWhenDone);
void STSafariDownloadURLWithFileName(NSURL* url, NSString* fileName);
void STSafariDownloadRequestWithFileName(NSURLRequest* req, NSString* fileName);

//Safari
void STSafariNewTabAction();
id STSafariCreateWKViewOrWebViewAtIndexAndShow(NSWindow* win, NSInteger idx, BOOL show);

id STSafariCurrentDocument();
NSWindow* STSafariCurrentBrowserWindow();
id STSafariCurrentTitle();
id STSafariCurrentURLString();
id STSafariCurrentWKView();
id STSafariWKViewForTabViewItem(id tabViewItem);
id STSafariTabViewItemForWKView(id wkView);
id /* NSTabView */ STSafariTabViewForWindow(NSWindow* win);
NSView* /* TabContentView */ STSafariTabContentViewForTabView(NSView* tabView);

void STSafariMoveTabViewItemToIndex(id tabViewItem, NSInteger idx);
void STSafariMoveTabToNewWindow(NSTabViewItem* item);
void STSafariMoveTabToOtherWindow(NSTabViewItem* itemToMove, NSWindow* destWindow, NSInteger destIndex, BOOL show);
void STSafariReloadTab(NSTabViewItem* item);
BOOL STSafariCanReloadTab(NSTabViewItem* item);

id STSafariBrowserWindowControllerForWKView(id wkView);
BOOL STSafariUsesWebKit2(id anyObject);
id STTabSwitcherForWinCtl(id winCtl);

NSInteger STSafariSelectedTabIndexForWindow(NSWindow* win);

NSImage* STSafariBundleImageNamed(NSString* name);
NSImage* STSafariBundleBookmarkImage();
NSImage* STSafariBundleHistoryImage();
NSImage* STSafariBundleReadinglistmage();

//WebBookmark, WebBookmarkLeaf

void STSafariAddSearchStringHistory(NSString* str);

const char* STSafariBookmarksControllerClass();
int STSafariWebBookmarkType(id webBookmark);
NSString* STSafariWebBookmarkURLString(id webBookmark);
NSString* STSafariWebBookmarkTitle(id webBookmark);



