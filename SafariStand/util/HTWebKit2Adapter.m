//
//  HTWebKit2Adapter.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

/*
 正直 WKRelease() は正しく使えているか自信がない。
 */

#import "HTWebKit2Adapter.h"
#import <objc/message.h>

/*
//from WebKit2/Shared/APIObject.h
enum Type {
    // Base types
    TypeNull = 0,
    TypeArray,
    TypeAuthenticationChallenge,
    TypeAuthenticationDecisionListener,
    TypeCertificateInfo,
    TypeContextMenuItem,
    TypeCredential,
    TypeData,//7
    TypeDictionary,//8
    TypeError,
    TypeGraphicsContext,
    TypeImage,
    TypeProtectionSpace,
    TypeSecurityOrigin,
    TypeSerializedScriptValue,
    TypeString,//15
    TypeURL,//16
    TypeURLRequest,
    TypeURLResponse,
    TypeUserContentURLPattern,
    
    // Base numeric types
    TypeBoolean,//20
    TypeDouble,
    TypeUInt64,
    
    // UIProcess types
    TypeApplicationCacheManager,
    TypeBackForwardList,
    TypeBackForwardListItem,
    TypeCacheManager,
    TypeContext,
    TypeCookieManager,
    TypeDatabaseManager,
    TypeDownload,
    TypeFormSubmissionListener,
    TypeFrame,//32
    TypeFramePolicyListener,
    TypeFullScreenManager,
    TypeGeolocationManager,
    TypeGeolocationPermissionRequest,
    TypeGeolocationPosition,
    TypeIconDatabase,
    TypeInspector,//39
    TypeKeyValueStorageManager,
    TypeMediaCacheManager,
    TypeNavigationData,
    TypeOpenPanelParameters,
    TypeOpenPanelResultListener,
    TypePage,
    TypePageGroup,
    TypePluginSiteDataManager,
    TypePreferences,
    
    // Bundle types
    TypeBundle,
    TypeBundleBackForwardList,
    TypeBundleBackForwardListItem,
    TypeBundleFrame,
    TypeBundleHitTestResult,
    TypeBundleInspector,
    TypeBundleNavigationAction,
    TypeBundleNodeHandle,
    TypeBundlePage,
    TypeBundlePageGroup,
    TypeBundlePageOverlay,
    TypeBundleRangeHandle,
    TypeBundleScriptWorld,
    
    // Platform specific
    TypeEditCommandProxy,
    TypeGrammarDetail,
    TypeTextChecker,
    TypeView
};

*/

NSString* htWKNSStringFromWKString(WKTypeRef wkStr)
{
    if(!wkStr || WKGetTypeID(wkStr)!=WKStringGetTypeID())return nil;
    
    size_t len=WKStringGetMaximumUTF8CStringSize(wkStr);
    void* buf;
    buf=malloc(len);
    //
    len=WKStringGetUTF8CString(wkStr, buf, len);//null 付き
    NSString* keyStr=[[NSString alloc]initWithBytes:buf length:len-1 encoding:NSUTF8StringEncoding];
    free(buf);
    
    return keyStr;
}

NSString* htNSStringFromWKURL(WKTypeRef wkURL)
{
    if(!wkURL || WKGetTypeID(wkURL)!=WKURLGetTypeID())return nil;
    
    WKTypeRef wkStr=WKURLCopyString(wkURL);
    NSString* result=htWKNSStringFromWKString(wkStr);
    WKRelease(wkStr);
    
    return result;
}

NSData* htNSDataFromWKData(WKTypeRef wkData)
{
    if(!wkData || WKGetTypeID(wkData)!=WKDataGetTypeID())return nil;
    
    return [NSData dataWithBytes:WKDataGetBytes(wkData) length:WKDataGetSize(wkData)];
}

NSArray* htWKDictionaryAllKeys(void* dic)
{
    NSMutableArray* result=[NSMutableArray array];
    if(dic && WKGetTypeID(dic)==WKDictionaryGetTypeID()){
        //WKArrayRef
        WKArrayRef wkAry=WKDictionaryCopyKeys(dic);
        int i;
        size_t cnt=WKArrayGetSize(wkAry);
        for(i=0; i<cnt; i++){
            WKTypeRef wkStr=WKArrayGetItemAtIndex(wkAry, i);
            NSString* keyStr=htWKNSStringFromWKString(wkStr);
            if(keyStr)[result addObject:keyStr];

        }
        WKRelease(wkAry);
    }
    return result;
}

WKTypeRef htWKDictionaryTypeRefForKey(void* dic, NSString* key)
{
    
    WKTypeRef wkStr=WKStringCreateWithUTF8CString([key cStringUsingEncoding:NSUTF8StringEncoding]);
    WKTypeRef val=WKDictionaryGetItemForKey(dic, wkStr);
    WKRelease(wkStr);

    return val;
}

//TypeString と TypeURL に対応。TypeURL の場合も NSString を返す
NSString* htWKDictionaryStringForKey(void* dic, NSString* key)
{
    
    WKTypeRef wkStr=WKStringCreateWithUTF8CString([key cStringUsingEncoding:NSUTF8StringEncoding]);
    WKTypeRef val=WKDictionaryGetItemForKey(dic, wkStr);
    WKRelease(wkStr);
    if(val){
        uint32_t type=WKGetTypeID(val);

        if(type==WKStringGetTypeID()) return htWKNSStringFromWKString(val);
        if(type==WKURLGetTypeID()) return htNSStringFromWKURL(val);
    }
    
    return nil;
}

void htWKGoToURL(id wkView, NSURL* urlToGo)
{
    if (!urlToGo || !wkView) {
        return;
    }
    
    WKPageRef pageRef=htWKPageRefForWKView(wkView);
    if (!pageRef) {
        return;
    }
    
    WKURLRef urlRef=WKURLCreateWithCFURL((__bridge CFURLRef)(urlToGo));
    WKPageLoadURL(pageRef, urlRef);
    WKRelease(urlRef);
    
}

WKPageRef htWKPageRefForWKView(id wkView)
{
    if (!wkView || ![wkView respondsToSelector:@selector(pageRef)]) {
        return nil;
    }
    
    WKPageRef pageRef=(__bridge WKPageRef)(objc_msgSend(wkView, @selector(pageRef)));
    return pageRef;
}


NSString* htMIMETypeForWKView(id wkView)
{
    NSString* result=nil;
    WKPageRef pageRef=htWKPageRefForWKView(wkView);
    WKFrameRef frameRef=WKPageGetMainFrame(pageRef);

    if (frameRef) {
        WKStringRef mime=WKFrameCopyMIMEType(frameRef);
        if (mime) {
            result=htWKNSStringFromWKString(mime);
            WKRelease(mime);
        }
    }

    return result;
}


//favicon
/*NSImage* htWKIconImageForWKView(id wkView, CGFloat desireSize)
{
    NSImage* img=nil;
    WKSize wkSize;
    
    WKPageRef pageRef=htWKPageRefForWKView(wkView);
    WKFrameRef frameRef=WKPageGetMainFrame(pageRef);
    WKURLRef urlRef=WKFrameCopyURL(frameRef);
    
    WKContextRef context=WKPageGetContext(pageRef);
    WKIconDatabaseRef iconDatabaseRef=WKContextGetIconDatabase(context);
    wkSize.width=desireSize;
    wkSize.height=desireSize;
    CGImageRef imgRef=WKIconDatabaseTryGetCGImageForURL(iconDatabaseRef, urlRef, wkSize);

    if (imgRef) {
        NSSize size=NSMakeSize(desireSize, desireSize);
        img=[[NSImage alloc]initWithCGImage:imgRef size:size];
        //CGImageRelease(imgRef); cause crash
    }
    WKRelease(urlRef);
    
    return img;
}
*/

NSImage* htWKIconImageForWKView(id wkView, CGFloat maxSize)
{
    NSImage* img=nil;
    
    WKPageRef pageRef=htWKPageRefForWKView(wkView);
    WKFrameRef frameRef=WKPageGetMainFrame(pageRef);
    WKURLRef urlRef=WKFrameCopyURL(frameRef);
    if (!urlRef) {
        return nil;
    }
    
    WKContextRef context=WKPageGetContext(pageRef);
    WKIconDatabaseRef iconDatabaseRef=WKContextGetIconDatabase(context);
    CFArrayRef images=WKIconDatabaseTryCopyCGImageArrayForURL(iconDatabaseRef, urlRef);
    if (images) {
        CGImageRef imgRefToUse=nil;

        CGImageRef imgRefHigh=nil;
        CGImageRef imgRefLow=nil;
        size_t widthHigh=9999;
        size_t widthLow=0;
        NSInteger i, cnt=CFArrayGetCount(images);
        for (i=0; i<cnt; i++) {
            CGImageRef imgRef=(CGImageRef)CFArrayGetValueAtIndex(images, i);
            size_t width=CGImageGetWidth(imgRef);
            if (width<=maxSize && width>widthLow) {
                imgRefLow=imgRef;
                widthLow=width;
            }else if(width>maxSize && width<widthHigh){
                imgRefHigh=imgRef;
                widthHigh=width;
            }
        }
        
        if(imgRefLow){
            imgRefToUse=imgRefLow;
            maxSize=0; //use CGImageRef size
        } else if(imgRefHigh) {
            imgRefToUse=imgRefHigh;
        } else {
            imgRefToUse=(CGImageRef)CFArrayGetValueAtIndex(images, 0);
        }
        
        if (imgRefToUse) {
            NSSize size=NSMakeSize(maxSize, maxSize);
            img=[[NSImage alloc]initWithCGImage:imgRefToUse size:size];
            //CGImageRelease(imgRef); cause crash
        }
        
        CFRelease(images);
    }
    WKRelease(urlRef);
    
    return img;
}


