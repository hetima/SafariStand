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

    NSMutableArray* _deliveries;
}

+ (NSString*)previewImageCachePath
{
    static NSString* previewImageCachePath=nil;
    if (!previewImageCachePath) {
        NSString* path=[NSHomeDirectory() stringByStandardizingPath];
        previewImageCachePath=[path stringByAppendingPathComponent:@"Library/Caches/com.apple.Safari/Webpage Previews(SafariStand)"];
    }
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:previewImageCachePath]) {
        [[NSFileManager defaultManager]createDirectoryAtPath:previewImageCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return previewImageCachePath;
}

- (id)init
{
    self = [super init];
    if (self) {
        _deliveries=[[NSMutableArray alloc]init];
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
 instantDelivery==YES だと即時 deliver、キューには入れない
 instantDelivery==NO だと即時 deliver、キューに入れるかもしれない
 */
- (void)requestPreviewImage:(STTabProxy*)tabProxy instantDelivery:(BOOL)instantDelivery
{
    [self invalidateRequestForTabProxy:tabProxy];
    NSString* domain=tabProxy.domain;
    if (![domain length]) {
        return;
    }
    
    NSString* URLString=[tabProxy URLString];
    NSString* nameHash=nil;
    STPreviewImageDelivery* delivery=[[STPreviewImageDelivery alloc]initWithTabProxy:tabProxy];
    
    //カスタムイメージ
    NSString* imagePath=[self userDefinedImagePathForName:domain];
    if (imagePath) {
        delivery.path=imagePath;
        [delivery deliver];
        return;
    }
    nameHash=[NSString stringWithFormat:@"%@%@", kSTPreviewImageOwnFilePrefix, domain];
    imagePath=[self previewImageCachePathForNameHash:nameHash];
    if (imagePath) {
        delivery.path=imagePath;
        [delivery deliver];
        return;
    }
    
    //favicon
    id wkView=[tabProxy wkView];
    NSImage* icon=htWKIconImageForWKView(wkView, 32.0);
    if (icon) {
        delivery.image=icon;
    }
    
    //favicon が小さい、もしくは存在しない
    if (icon.size.width<32) {
        NSURL* url=[NSURL URLWithString:URLString];

        //とりあえずドメイントップページだった場合のみ画像を取ってくる
        if ([[url path]length]==1) { // @"/"
            delivery.nameHash=nameHash;
            //小さい favicon を取得済みだったらとりあえず投げる
            if (delivery.image||delivery.path) {
                [delivery deliver];

                delivery.image=nil;
                delivery.path=nil;
            }
            if(!instantDelivery) {
                [_deliveries addObject:delivery];
                [self fetchDomainPreviewImage:(STTabProxy*)tabProxy];
                return;
            }
        }
    }
    
    if (delivery.path || delivery.image) {
        [delivery deliver];
    }
}

- (NSString*)userDefinedImagePathForName:(NSString*)name
{
    NSString* parentPath=[STCSafariStandCore standLibraryPath:@"WebpagePreviews"];
    return [self imagePathForName:name inDirectory:parentPath];
}

- (NSString*)previewImageCachePathForNameHash:(NSString*)nameHash
{
    NSString* parentPath=[STPreviewImageManager previewImageCachePath];
    return [self imagePathForName:nameHash inDirectory:parentPath];
}

- (NSString*)imagePathForName:(NSString*)nameHash inDirectory:(NSString*)parentPath
{
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


#pragma mark - preview cache

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
    z=document.evaluate(\"//meta[@property='og:image']\", document.head).iterateNext();if(z)return z.content;\
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
                         NSString* path=[STPreviewImageManager previewImageCachePath];
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
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self wbpagePreviewCacheUpdated:@[path]];
                         });
                         
                     }
                 }
             });
         }
         
     }];
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


