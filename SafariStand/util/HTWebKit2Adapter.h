//
//  HTWebKit2Adapter.h
//  SafariStand


#import <Foundation/Foundation.h>

/*
 WebKit2のソースからヘッダとってくる
 */
//#import <WebKit2/WebKit2.h>
//#import <WebKit2/WKURLCF.h>

/*
 もしくは使うものだけ抜き出してこんな風に貼り付ける
 */
typedef uint32_t WKTypeID;
typedef const void* WKTypeRef;

typedef const struct OpaqueWKArray* WKArrayRef;
typedef struct OpaqueWKArray* WKMutableArrayRef;

typedef const struct OpaqueWKDictionary* WKDictionaryRef;
typedef struct OpaqueWKDictionary* WKMutableDictionaryRef;

typedef const struct OpaqueWKBoolean* WKBooleanRef;
typedef const struct OpaqueWKCertificateInfo* WKCertificateInfoRef;
typedef const struct OpaqueWKConnection* WKConnectionRef;
typedef const struct OpaqueWKContextMenuItem* WKContextMenuItemRef;
typedef const struct OpaqueWKData* WKDataRef;
typedef const struct OpaqueWKDouble* WKDoubleRef;
typedef const struct OpaqueWKError* WKErrorRef;
typedef const struct OpaqueWKGraphicsContext* WKGraphicsContextRef;
typedef const struct OpaqueWKImage* WKImageRef;
typedef const struct OpaqueWKPointRef* WKPointRef;
typedef const struct OpaqueWKRectRef* WKRectRef;
typedef const struct OpaqueWKRenderLayer* WKRenderLayerRef;
typedef const struct OpaqueWKRenderObject* WKRenderObjectRef;
typedef const struct OpaqueWKSecurityOrigin* WKSecurityOriginRef;
typedef const struct OpaqueWKSerializedScriptValue* WKSerializedScriptValueRef;
typedef const struct OpaqueWKSizeRef* WKSizeRef;
typedef const struct OpaqueWKString* WKStringRef;
typedef const struct OpaqueWKUInt64* WKUInt64Ref;
typedef const struct OpaqueWKURL* WKURLRef;
typedef const struct OpaqueWKURLRequest* WKURLRequestRef;
typedef const struct OpaqueWKURLResponse* WKURLResponseRef;
typedef const struct OpaqueWKUserContentURLPattern* WKUserContentURLPatternRef;

typedef const struct OpaqueWKFrame* WKFrameRef;
typedef const struct OpaqueWKPage* WKPageRef;



extern WKTypeID WKGetTypeID(WKTypeRef type);
extern WKTypeRef WKRetain(WKTypeRef type);
extern void WKRelease(WKTypeRef type);

//WKString
extern WKTypeID WKStringGetTypeID();
extern WKStringRef WKStringCreateWithUTF8CString(const char* string);
extern size_t WKStringGetMaximumUTF8CStringSize(WKStringRef string);
extern size_t WKStringGetUTF8CString(WKStringRef string, char* buffer, size_t bufferSize);

//WKData
extern WKTypeID WKDataGetTypeID();
extern WKDataRef WKDataCreate(const unsigned char* bytes, size_t size);
extern const unsigned char* WKDataGetBytes(WKDataRef data);
extern size_t WKDataGetSize(WKDataRef data);

//WKURL
extern WKTypeID WKURLGetTypeID();
extern WKStringRef WKURLCopyString(WKURLRef url);
extern WKURLRef WKURLCreateWithCFURL(CFURLRef URL);
extern CFURLRef WKURLCopyCFURL(CFAllocatorRef alloc, WKURLRef URL);

//WKDictionary
extern WKTypeID WKDictionaryGetTypeID();
extern WKTypeRef WKDictionaryGetItemForKey(WKDictionaryRef dictionary, WKStringRef key);
extern size_t WKDictionaryGetSize(WKDictionaryRef dictionary);
extern WKArrayRef WKDictionaryCopyKeys(WKDictionaryRef dictionary);

//WKArray
extern WKTypeID WKArrayGetTypeID();
extern WKArrayRef WKArrayCreate(WKTypeRef* values, size_t numberOfValues);
extern WKTypeRef WKArrayGetItemAtIndex(WKArrayRef array, size_t index);
extern size_t WKArrayGetSize(WKArrayRef array);

//WKPage
extern void WKPageLoadURL(WKPageRef page, WKURLRef url);

//WKFrame
extern WKURLRef WKFrameCopyURL(WKFrameRef frame);
typedef void (*WKFrameGetResourceDataFunction)(WKDataRef data, WKErrorRef error, void* functionContext);
extern void WKFrameGetMainResourceData(WKFrameRef frame, WKFrameGetResourceDataFunction function, void* functionContext);
extern void WKFrameGetResourceData(WKFrameRef frame, WKURLRef resourceURL, WKFrameGetResourceDataFunction function, void* functionContext);


typedef void (*WKFrameGetWebArchiveFunction)(WKDataRef archiveData, WKErrorRef error, void* functionContext);
extern void WKFrameGetWebArchive(WKFrameRef frame, WKFrameGetWebArchiveFunction function, void* functionContext);

extern WKFrameRef WKPageGetMainFrame(WKPageRef page);

/*
 抜き出し終わり
 */





NSString* htWKNSStringFromWKString(WKTypeRef wkStr);
NSString* htNSStringFromWKURL(WKTypeRef wkURL);
NSData* htNSDataFromWKData(WKTypeRef wkData);

NSArray* htWKDictionaryAllKeys(void* dic);
WKTypeRef htWKDictionaryTypeRefForKey(void*dic, NSString* key);
NSString* htWKDictionaryStringForKey(void*dic, NSString* key);

void htWKGoToURL(id wkView, NSURL* urlToGo);
WKPageRef htWKPageRefForWKView(id wkView);
