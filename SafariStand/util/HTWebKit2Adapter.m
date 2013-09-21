//
//  HTWebKit2Adapter.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif

/*
 正直 WKRelease() は正しく使えているか自信がない。
 */

#import "HTWebKit2Adapter.h"

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

NSString* htWKNSStringFromWKString(WKTypeRef wkStr){
    if(!wkStr || WKGetTypeID(wkStr)!=WKStringGetTypeID())return nil;
    
    size_t len=WKStringGetMaximumUTF8CStringSize(wkStr);
    void* buf;
    buf=malloc(len);
    //
    len=WKStringGetUTF8CString(wkStr, buf, len);//null 付き
    NSString* keyStr=[[NSString alloc]initWithBytes:buf length:len-1 encoding:NSUTF8StringEncoding];
    free(buf);
    
    return [keyStr autorelease];
}
NSString* htNSStringFromWKURL(WKTypeRef wkURL){
    if(!wkURL || WKGetTypeID(wkURL)!=WKURLGetTypeID())return nil;
    
    WKTypeRef wkStr=WKURLCopyString(wkURL);
    NSString* result=htWKNSStringFromWKString(wkStr);
    WKRelease(wkStr);
    
    return result;
}
NSData* htNSDataFromWKData(WKTypeRef wkData){
    if(!wkData || WKGetTypeID(wkData)!=WKDataGetTypeID())return nil;
    
    return [NSData dataWithBytes:WKDataGetBytes(wkData) length:WKDataGetSize(wkData)];
}

NSArray* htWKDictionaryAllKeys(void* dic){
    NSMutableArray* result=[NSMutableArray array];
    if(dic && WKGetTypeID(dic)==WKDictionaryGetTypeID()){//8==TypeDictionary
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

WKTypeRef htWKDictionaryTypeRefForKey(void* dic, NSString* key){
    
    WKTypeRef wkStr=WKStringCreateWithUTF8CString([key cStringUsingEncoding:NSUTF8StringEncoding]);
    WKTypeRef val=WKDictionaryGetItemForKey(dic, wkStr);
    WKRelease(wkStr);

    return val;
}

//TypeString と TypeURL に対応。TypeURL の場合も NSString を返す
NSString* htWKDictionaryStringForKey(void* dic, NSString* key){
    
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



