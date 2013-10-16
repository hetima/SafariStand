//
//  STWKClientHook.m
//  SafariStand


#import "SafariStand.h"
#import "STWKClientHook.h"
#import "STTabProxy.h"
#import "HTWebKit2Adapter.h"
#import "HTSymbolHook.h"

// WKPageRef から WKView を取得
// client 関数内から WKView が欲しい場合これを使う
// 内部構造あまり把握できてないけど、とりあえずこれで取得できた
static void* STWK_WKPageRefGetWKView(WKPageRef page)
{
    // PageClientImpl(だと思う) を取得
    void* pageClient = *(void **)((void **)page + 3);
    // WKView を取得
    void* wkView= *(void **)((void **)pageClient + 1);
    return wkView;
}

//typedef void (*WKPageCallback)(WKPageRef page, const void* clientInfo);

//Safari::WK::didStartProgress(OpaqueWKPage const*, void const*)
//__ZN6Safari2WKL16didStartProgressEPK12OpaqueWKPagePKv
void (*orig_didStartProgress)(WKPageRef, const void*);
void STWK_didStartProgress(WKPageRef page, const void* clientInfo)
{
    orig_didStartProgress(page, clientInfo);
    
    void* wkView=STWK_WKPageRefGetWKView(page);
    STTabProxy* proxy=[STTabProxy tabProxyForWKView:(__bridge id)wkView];
    [proxy didStartProgress];
}

//Safari::WK::didFinishProgress(OpaqueWKPage const*, void const*)
//__ZN6Safari2WKL17didFinishProgressEPK12OpaqueWKPagePKv
void (*orig_didFinishProgress)(WKPageRef, const void*);
void STWK_didFinishProgress(WKPageRef page, const void* clientInfo)
{
    orig_didFinishProgress(page, clientInfo);

    void* wkView=STWK_WKPageRefGetWKView(page);
    STTabProxy* proxy=[STTabProxy tabProxyForWKView:(__bridge id)wkView];
    [proxy didFinishProgress];
}

//Safari::WK::showPage(OpaqueWKPage const*, void const*)
//__ZN6Safari2WKL8showPageEPK12OpaqueWKPagePKv
void (*orig_showPage)(WKPageRef, const void*);
void STWK_showPage(WKPageRef page, const void* clientInfo)
{
    //JavaScriptで開いたウインドウにはサイドバーを自動表示しないようにする
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpSidebarShowsDefault]) {
        
        void* wkView=STWK_WKPageRefGetWKView(page);
        id winCtl=STSafariBrowserWindowControllerForWKView((__bridge id)(wkView));
        id tabView=STSafariTabViewForWindow([winCtl window]);
        if ([tabView numberOfTabViewItems]<=1){
            [winCtl htaoSetValue:@YES forKey:kAOValueNotShowSidebarAuto];
        }
    }
    
    orig_showPage(page, clientInfo);

}

void STWKClientHook()
{
    HTSymbolHook* hook=[HTSymbolHook symbolHookWithImageNameSuffix:@"/Safari.framework/Versions/A/Safari"];
    if (hook.valid) {
        [hook overrideSymbol:@"__ZN6Safari2WKL16didStartProgressEPK12OpaqueWKPagePKv"
                     withPtr:(void*)STWK_didStartProgress
               reentryIsland:(void**)&orig_didStartProgress];
        [hook overrideSymbol:@"__ZN6Safari2WKL17didFinishProgressEPK12OpaqueWKPagePKv"
                     withPtr:(void*)STWK_didFinishProgress
               reentryIsland:(void**)&orig_didFinishProgress];
        [hook overrideSymbol:@"__ZN6Safari2WKL8showPageEPK12OpaqueWKPagePKv"
                     withPtr:(void*)STWK_showPage
               reentryIsland:(void**)&orig_showPage];
    }
}