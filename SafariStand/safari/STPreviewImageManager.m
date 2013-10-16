//
//  STPreviewImageManager.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STPreviewImageManager.h"
#import "STTabProxy.h"
#import "STFakeJSCommand.h"
#import "HTWebKit2Adapter.h"

#define kSTPreviewImageOwnFilePrefix @"STP_"

@implementation STPreviewImageManager {
    FSEventStreamRef _eventStream;
    NSMutableArray* _deliveries;
}

- (id)init
{
    self = [super init];
    if (self) {
        _deliveries=[[NSMutableArray alloc]init];
        [self setupPreviewEventStream];
    }
    return self;
}

#pragma mark -

- (void)invalidateRequestForTabProxy:(STTabProxy*)tabProxy
{
    NSEnumerator* re=[_deliveries reverseObjectEnumerator];
    STPreviewImageDelivery* delivery;
    while (delivery=[re nextObject]) {
        if (delivery.tabProxy==tabProxy || delivery.tabProxy==nil) {
            [_deliveries removeObjectIdenticalTo:delivery];
        }
    }
}

/*
 instantDelivery==YES だとなるべく即時 deliver。Webpage Previews キャッシュ使わない場合は意味がないフラグになる
 */
- (void)requestPreviewImage:(STTabProxy*)tabProxy instantDelivery:(BOOL)instantDelivery
{
    [self invalidateRequestForTabProxy:tabProxy];
    NSString* URLString=[tabProxy URLString];
    NSString* nameHash=nil;
    STPreviewImageDelivery* delivery=[[STPreviewImageDelivery alloc]initWithTabProxy:tabProxy];
    
    if ([URLString hasPrefix:@"http:"]) {
        id wkView=[tabProxy wkView];
        NSImage* icon=htWKIconImageForWKView(wkView, 32.0);
        if (icon) {
            delivery.image=icon;
        }else{
        
            nameHash=HTMD5StringFromString(URLString);
            if (instantDelivery) {
                delivery.path=[self instantPreviewImagePathForNameHash:nameHash];
                // ここで path が nil の場合更新待ちになるのだが、読み込みは終わってるのでたぶん更新来ない
                // _deliveries の中で待ちぼうけになるだけで実害はあまりないけど気になる
            }
        }
    }else{
        nameHash=[NSString stringWithFormat:@"%@%@", kSTPreviewImageOwnFilePrefix, tabProxy.domain];
        
        NSString* imagePath=[self instantPreviewImagePathForNameHash:nameHash];
        if (imagePath) {
            delivery.path=imagePath;
        }else{
            [self fetchDomainPreviewImage:(STTabProxy*)tabProxy];
        }
    }
    
    delivery.nameHash=nameHash;
    
    if (delivery.path || delivery.image) {
        [delivery deliver];
    }else{
        [_deliveries addObject:delivery];
    }
}

- (NSString*)instantPreviewImagePathForNameHash:(NSString*)nameHash
{
    NSString* parentPath=STSafariWebpagePreviewsPath();
    
    NSArray* exts=@[@"jpeg", @"png", @"jpg"];
    for (NSString* ext in exts) {
        NSString* name=[NSString stringWithFormat:@"%@.%@", nameHash, ext];
        NSString* path=[parentPath stringByAppendingPathComponent:name];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            return path;
        }
    }
    return nil;
}

#pragma mark - Self preview cache

- (void)fetchDomainPreviewImage:(STTabProxy*)tabProxy
{

    NSURL* baseURL=[NSURL URLWithString:[tabProxy URLString]];
    
    [STFakeJSCommand doScript:@"(function(){ \
    var z=document.getElementsByName('msapplication-TileImage');\
    if(z.length){\
        var y=document.getElementsByName('msapplication-TileColor');\
        if(y.length)y=y[0].content;else y='#ffffff';\
        return {'tileImage':z[0].content,'tileColor':y}\
    }\
    z=document.evaluate(\"//meta[@itemprop='image']\", document.head).iterateNext();if(z)return z.content;\
    })();"
     
     onTarget:tabProxy.tabViewItem completionHandler:^(id result){
         NSString* path;
         NSString* bgColorString=nil;
         if ([result isKindOfClass:[NSDictionary class]]) {
             path=[result objectForKey:@"tileImage"];
             bgColorString=[[result objectForKey:@"tileColor"]lowercaseString];
             if ([bgColorString isEqualToString:@"#ffffff"] || [bgColorString isEqualToString:@"#fff"]) {
                 bgColorString=nil;
             }
         }else{
             path=result;
         }
         if (![path isKindOfClass:[NSNull class]] && [path length]>2) {
             NSString* host=[baseURL host];
             NSURL* url=[NSURL URLWithString:path relativeToURL:baseURL];
             dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
             dispatch_async(q, ^{
                 NSURLRequest* request=[NSURLRequest requestWithURL:url];
                 NSURLResponse* response=nil;
                 NSError *error=nil;
                 NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                 if (!error) {
                     NSString* mime=[response MIMEType];
                     if ([mime length]>8 && [mime hasPrefix:@"image/"]) {
                         mime=[mime substringFromIndex:6];
                     }else{
                         mime=[path pathExtension];
                     }
                     if (mime) {
                         NSColor* bgColor=HTColorFromHTMLString(bgColorString);
                         NSString* path=STSafariWebpagePreviewsPath();
                         NSString* name=[NSString stringWithFormat:@"%@%@.%@", kSTPreviewImageOwnFilePrefix, host, mime];
                         path=[path stringByAppendingPathComponent:name];
                         if (bgColor) {
                             NSImage* image=[[NSImage alloc]initWithData:data];
                             NSImage* renderImage=HTImageWithBackgroundColor(image, bgColor);
                             NSData* renderData=HTPNGDataRepresentation(renderImage);
                             if (renderData) {
                                 data=renderData;
                             }
                         }
                         [data writeToFile:path atomically:YES];
                     }
                 }
             });
         }
         
     }];
}


#pragma mark - Safari preview cache

#define STTabProxyPreviewLatency			((CFTimeInterval)2.0)

static void STTabProxyPreviewEventsCallback(
                                            ConstFSEventStreamRef streamRef,
                                            void *callbackCtxInfo,
                                            size_t numEvents,
                                            void *eventPaths, // CFArrayRef
                                            const FSEventStreamEventFlags eventFlags[],
                                            const FSEventStreamEventId eventIds[])
{
	NSArray *eventPathsArray=(__bridge NSArray *)eventPaths;
    NSMutableArray* ary=[NSMutableArray arrayWithCapacity:numEvents];

	for (NSUInteger i = 0; i < numEvents; ++i) {
		//FSEventStreamEventFlags flags = eventFlags[i];
		//FSEventStreamEventId identifier = eventIds[i];
        NSString *eventPath = [eventPathsArray objectAtIndex:i];
        
        if ([[NSFileManager defaultManager]fileExistsAtPath:eventPath] &&
            ([eventPath hasSuffix:@"jpeg"]||[[eventPath lastPathComponent]hasPrefix:kSTPreviewImageOwnFilePrefix]) ) {
            [ary addObject:eventPath];
            
        }
	}
    
    if ([ary count]) {
        STPreviewImageManager *ctl=(__bridge STPreviewImageManager *)callbackCtxInfo;
        [ctl wbpagePreviewCacheUpdated:ary];
    }
}

- (void)wbpagePreviewCacheUpdated:(NSArray*)paths
{
    for (NSString* path in paths) {
        NSString* nameHash=[[path lastPathComponent]stringByDeletingPathExtension];
        for (STPreviewImageDelivery* delivery in _deliveries) {
            if ([nameHash isEqualToString:delivery.nameHash]) {
                delivery.path=path;
                [delivery deliver];
                [_deliveries removeObjectIdenticalTo:delivery];
                break;
            }
        }
    }
}

- (void)invalidatePreviewEventStream
{
    if (_eventStream) {
        FSEventStreamStop(_eventStream);
        FSEventStreamInvalidate(_eventStream);
        FSEventStreamRelease(_eventStream);
        _eventStream = nil;
    }
}

- (void)setupPreviewEventStream
{
    [self invalidatePreviewEventStream];
    NSString* path=STSafariWebpagePreviewsPath();
    if (path) {
        NSArray* watchPaths=@[path];
        FSEventStreamCreateFlags   flags = (kFSEventStreamCreateFlagUseCFTypes |
                                            kFSEventStreamCreateFlagWatchRoot);
        flags |= kFSEventStreamCreateFlagFileEvents;
        
        FSEventStreamContext callbackCtx;
        callbackCtx.version			= 0;
        callbackCtx.info			= (__bridge void *)self;
        callbackCtx.retain			= NULL;
        callbackCtx.release			= NULL;
        callbackCtx.copyDescription	= NULL;
        
        _eventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                           &STTabProxyPreviewEventsCallback,
                                           &callbackCtx,
                                           (__bridge CFArrayRef)watchPaths,
                                           kFSEventStreamEventIdSinceNow,
                                           STTabProxyPreviewLatency,
                                           flags);
        FSEventStreamScheduleWithRunLoop(_eventStream, [[NSRunLoop currentRunLoop]getCFRunLoop], kCFRunLoopDefaultMode);
        if (!FSEventStreamStart(_eventStream)) {
            
        }
    }
}

#pragma mark -

- (NSString*)suitableImageURLStringForTabProxy:(STTabProxy*)tabProxy
{
    return nil;
}

@end



@implementation STPreviewImageDelivery

- (id)initWithTabProxy:(STTabProxy*)tabProxy
{
    self = [super init];
    if (self) {
        self.tabProxy=tabProxy;
    }
    return self;
}

- (void)dealloc
{
    LOG(@"deliver d");
}

- (void)deliver
{
    [self.tabProxy previewImageDelivered:self];
    LOG(@"%@,%@",[self.path lastPathComponent],self.nameHash);
}
@end


