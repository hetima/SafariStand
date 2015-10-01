//
//  STCheckCompatibility.m
//  SafariStand
//
//  Created by hetima on 2015/09/29.
//
//

#import "STCheckCompatibility.h"
#import "STSafariConnect.h"
#import "HTSymbolHook.h"

@implementation STCheckCompatibility


+ (NSInteger)checkClass:(NSString*)className method:(NSString*)method
{
    if ([method hasPrefix:@"+"]) {
        method=[method substringFromIndex:1];
        return [self checkClass:className classMethod:method];
    }
    
    if (!className || [className length]==0 || !method || [method length]==0) {
        return 0;
    }
    
    
    Class cls=NSClassFromString(className);
    if (!cls) {
        NSLog(@"%@ class not found", className);
        return 1;
    }
    
    if (![cls instancesRespondToSelector:NSSelectorFromString(method)]) {
        NSLog(@"-[%@ %@]", className, method);
        return 1;
    }
    return 0;
}


+ (NSInteger)checkClass:(NSString*)className classMethod:(NSString*)method
{
    if (!className || [className length]==0 || !method || [method length]==0) {
        return 0;
    }
    
    Class cls=NSClassFromString(className);
    if (!cls) {
        NSLog(@"%@ class not found", className);
        return 1;
    }
    
    if (![cls respondsToSelector:NSSelectorFromString(method)]) {
        NSLog(@"+[%@ %@]", className, method);
        return 1;
    }

    return 0;
    
}

+ (NSInteger)checkImageNameSuffix:(NSString*)imageName symbolName:(NSString*)symbolName
{
    if (!imageName || [imageName length]==0 || !symbolName || [symbolName length]==0) {
        return 0;
    }
    

    HTSymbolHook* hook=[HTSymbolHook symbolHookWithImageNameSuffix:imageName];
    void* ptr=[hook symbolPtrWithSymbolName:symbolName];

    if (!ptr) {
        NSLog(@"symbolName not found:%@", symbolName);
        return 1;
    }
    
    return 0;
    
}

+ (void)check
{
    NSInteger errorCount=0;
    //STSafariConnect
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"orderedTabViewItems"];
    errorCount=[self checkClass:@"BrowserDocumentController" method:@"goToURL:windowPolicy:"];
    errorCount=[self checkClass:@"BrowserDocumentController" method:@"goToRequest:tabLabel:windowPolicy:tabPlacementHint:"];
    errorCount=[self checkClass:@"DownloadMonitorOld" method:@"+sharedDownloadMonitor"];
    errorCount=[self checkClass:@"DownloadMonitorOld" method:@"startDownloadForRequest:mayOpenWhenDone:removeEntryWhenDone:"];
    errorCount=[self checkClass:@"DownloadMonitorOld" method:@"startDownloadForRequest:mayOpenWhenDone:allowOverwrite:removeEntryWhenDone:path:tags:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"browserDocument"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_createTabWithView:atIndex:options:"];
    errorCount=[self checkClass:@"BrowserDocument" method:@"createWKView"];
    errorCount=[self checkClass:@"BrowserDocumentController" method:@"activateFrontmostBrowserDocumentIfAvailable"];
    errorCount=[self checkClass:@"BrowserDocumentController" method:@"openEmptyBrowserDocument"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"selectedTab"];
    errorCount=[self checkClass:@"URLWindowPolicyDecider" method:@"+windowPolicyFromCurrentEventRequireCommandKey:"];
    errorCount=[self checkClass:@"BrowserDocumentController" method:@"frontmostBrowserDocument"];
    errorCount=[self checkClass:@"BrowserDocument" method:@"URLString"];
    errorCount=[self checkClass:@"BrowserDocument" method:@"currentWKView"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"selectedTabIndex"];
    errorCount=[self checkClass:@"BrowserTabViewItem" method:@"wkView"];
    errorCount=[self checkClass:@"BrowserTabViewItem" method:@"browserTab"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"tabViewItemForWKView:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"tabSwitcher"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"moveTab:toIndex:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_moveTabToNewWindow:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"moveTabFromOtherWindow:toIndex:andSelect:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_reloadTab:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"canReloadTab:"];
    errorCount=[self checkClass:@"BrowserWKView" method:@"browserWindowControllerMac"];
    errorCount=[self checkClass:@"BrowserDocument" method:@"browserWindowControllerMac"];
    errorCount=[self checkClass:@"RecentWebSearchesController" method:@"+sharedController"];
    errorCount=[self checkClass:@"WebBookmark" method:@"bookmarkType"];
    errorCount=[self checkClass:@"WebBookmarkLeaf" method:@"URLString"];
    errorCount=[self checkClass:@"WebBookmark" method:@"title"];
    errorCount=[self checkClass:@"WebBookmark" method:@"icon"];
    errorCount=[self checkClass:@"WebBookmark" method:@"UUID"];
    errorCount=[self checkClass:@"WBSQuickWebsiteSearchController" method:@"+sharedController"];
    //STTabProxyController
    errorCount=[self checkClass:@"BrowserTabViewItem" method:@"initWithBrowserWindowControllerMac:"];
    errorCount=[self checkClass:@"TabBarView" method:@"insertTabBarViewItem:atIndex:"];
    errorCount=[self checkClass:@"TabBarView" method:@"removeTabBarViewItem:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_moveTabViewItem:toIndex:"];
    errorCount=[self checkClass:@"TabBarView" method:@"selectTabBarViewItem:"];
    //errorCount=[self checkClass:@"BrowserWindowContentView" method:@"setTabSwitcher:"];
    errorCount=[self checkClass:@"BrowserTabViewItem" method:@"setLabel:"];
    errorCount=[self checkClass:@"ResizableContentContainer" method:@"didAddSubview:"];
    //STTabProxy
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_selectTab:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"tryToCloseOtherTabsWhenReady:"];
    
    //STWKClientHook
    errorCount=[self checkImageNameSuffix:@"/Safari.framework/Versions/A/Safari" symbolName:@"__ZN6Safari2WKL16didStartProgressEPK12OpaqueWKPagePKv"];
    errorCount=[self checkImageNameSuffix:@"/Safari.framework/Versions/A/Safari" symbolName:@"__ZN6Safari2WKL17didFinishProgressEPK12OpaqueWKPagePKv"];
    errorCount=[self checkImageNameSuffix:@"/Safari.framework/Versions/A/Safari" symbolName:@"__ZN6Safari2WKL8showPageEPK12OpaqueWKPagePKv"];
    errorCount=[self checkImageNameSuffix:@"" symbolName:@""];
    
    //STFakeJSCommand
    errorCount=[self checkClass:@"BrowserWKView" method:@"handleDoJavaScriptCommand:"];
    errorCount=[self checkClass:@"BrowserTabViewItem" method:@"handleDoJavaScriptCommand:"];
    
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    
    //STActionMessageModule
    errorCount=[self checkClass:@"NSMenu" method:@"safari_addMenuItemForBookmark:withTabPlacementHint:"];
    errorCount=[self checkClass:@"FavoriteButton" method:@"_goToBookmark"];
    //STSToolbarModule
    errorCount=[self checkClass:@"ToolbarController" method:@"toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:"];
    errorCount=[self checkClass:@"ToolbarController" method:@"toolbarAllowedItemIdentifiers:"];
    //STSContextMenuModule.m
    errorCount=[self checkClass:@"WKMenuTarget" method:@"setMenuProxy:"];
    //STConsolePanelModule
    errorCount=[self checkClass:@"BookmarksSidebarViewController" method:@"_openBookmarkAndGiveFocusToWebContent:"];
    errorCount=[self checkClass:@"BookmarksSidebarViewController" method:@"_openInCurrentTab:"];
    errorCount=[self checkClass:@"BookmarksSidebarViewController" method:@"_openInNewTab:"];
    errorCount=[self checkClass:@"BookmarksSidebarViewController" method:@"_openInNewWindow:"];
    errorCount=[self checkClass:@"BookmarksUndoController" method:@"initWithUndoManager:"];
    //STQuickSearchModule
    errorCount=[self checkClass:@"NSString" method:@"safari_bestURLForUserTypedString"];
    errorCount=[self checkClass:@"WBSURLCompletionDatabase" method:@"getBestMatchesForTypedString:topHits:matches:limit:"];
    //STSTabBarModule
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"isTabBarVisible"];
    errorCount=[self checkClass:@"TabBarView" method:@"_updateButtonsAndLayOutAnimated:"];
    errorCount=[self checkClass:@"TabBarView" method:@"scrollWheel:"];
    errorCount=[self checkClass:@"TabBarView" method:@"_buttonWidthForNumberOfButtons:inWidth:remainderWidth:"];
    errorCount=[self checkClass:@"TabBarView" method:@"_shouldLayOutButtonsToAlignWithWindowCenter"];
    errorCount=[self checkClass:@"TabBarView" method:@"_tabIndexAtPoint:"];
    errorCount=[self checkClass:@"TabButton" method:@"initWithFrame:tabBarViewItem:"];
    errorCount=[self checkClass:@"TabButton" method:@"closeButton"];//x
    errorCount=[self checkClass:@"BrowserTabViewItem" method:@"scrollableTabButton"];//x
    //STKeyHandlerModule
    errorCount=[self checkClass:@"BookmarksController" method:@"goToNthFavoriteLeaf:"];
    //STSDownloadModule
    errorCount=[self checkClass:@"DownloadsPopoverViewController" method:@"+sharedController"];
    errorCount=[self checkClass:@"DownloadsPopoverViewController" method:@"popover"];
    errorCount=[self checkClass:@"NSFileManager" method:@"safari_pathWithUniqueFilenameForPath:"];//?
    errorCount=[self checkClass:@"NSFileManager" method:@"_webkit_pathWithUniqueFilenameForPath:"];//?
    errorCount=[self checkClass:@"AppController" method:@"showDownloads:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"toggleDownloadsPopover:"];
    //STSidebarModule
    //errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_shouldShowTabBar"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_shouldShowTabBarIgnoringVisualTabPicker"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_moreThanOneTabShowing"];
    errorCount=[self checkClass:@"NSTabView" method:@"contentRect"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"showWindow:"];
    //errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"tabBarEnclosureView"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"isTabBarVisible"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"toggleTabBar:"];
    //STTabPickerModule
    errorCount=[self checkClass:@"VisualTabPickerViewController" method:@"orderedTabItemsInVisualTabPickerGridView:"];
    errorCount=[self checkClass:@"VisualTabPickerViewController" method:@"orderedTabItemsInVisualTabPickerGridView:"];
    errorCount=[self checkClass:@"VisualTabPickerViewController" method:@"indexOfSelectedTab"];
    errorCount=[self checkClass:@"VisualTabPickerViewController" method:@"shouldStackMultipleThumbnailsInOneContainerIfPossible"];
    errorCount=[self checkClass:@"VisualTabPickerViewController" method:@"loadView"];
    errorCount=[self checkClass:@"VisualTabPickerViewController" method:@"_reloadGridView"];
    errorCount=[self checkClass:@"VisualTabPickerViewController" method:@"control:textView:doCommandBySelector:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"toggleVisualTabPicker:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"isShowingVisualTabPicker"];
    
    //STTabStockerModule
    errorCount=[self checkImageNameSuffix:@"/Safari.framework/Versions/A/Safari" symbolName:@"__ZN6Safari10BrowserTab26restoreFromBrowserTabStateEP25BrowserTabPersistentStateNS_15AllowJavaScriptE"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_closeTabWithoutConfirming:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"usesPrivateBrowsing"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"_closeOtherTabsWithoutConfirming:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"windowWillClose:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"orderedTabViewItems"];
    //STFavoriteButtonModule
    errorCount=[self checkClass:@"FavoriteButton" method:@"setBookmark:"];
    errorCount=[self checkClass:@"FavoriteButton" method:@"menu"];
    errorCount=[self checkClass:@"FavoriteButton" method:@"canDragHorizontally:fromMouseDown:"];
    errorCount=[self checkClass:@"FavoriteButton" method:@"_didRecognizeLongPressGesture:"];
    errorCount=[self checkClass:@"FavoriteButton" method:@"_canAcceptDroppedBookmarkAtPoint:"];
    errorCount=[self checkClass:@"FavoriteButton" method:@"hasContentsMenu"];
    errorCount=[self checkClass:@"CALayer" method:@"setCompositingFilter:"];
    errorCount=[self checkClass:@"BrowserWindowControllerMac" method:@"favoritesBarView"];
    errorCount=[self checkClass:@"FavoritesBarView" method:@"refreshButtons"];
    errorCount=[self checkClass:@"FavoriteButton" method:@"bookmark"];
    errorCount=[self checkClass:@"FavoriteButtonCell" method:@"setIndicator:"];
    
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"" method:@""];
    errorCount=[self checkClass:@"BrowserTabPersistentState" method:@"initWithBrowserTab:"];
    
    
    
}


@end
