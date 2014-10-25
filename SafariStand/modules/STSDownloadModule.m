//
//  STSDownloadModule.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STSDownloadModule.h"
#import "HTWebKit2Adapter.h"
#import "STClassifyDownloadAdvSheetCtl.h"
#import "NSFileManager+SafariStand.h"

#import "STConsolePanelModule.h"

@implementation STSDownloadModule {
    STClassifyDownloadAdvSheetCtl* _advSheetCtl;
    SEL _nameForPathSelector;
}


//info is retained
void copyImageToDownloadFolderCallBack(void* data, void* error, CFDictionaryRef info)
{
    @autoreleasepool {
        NSDictionary* dic=(__bridge NSDictionary*)info;

        NSString* fileName=[dic objectForKey:@"fileName"];

        NSString* outDir=STSafariDownloadDestinationWithFileName(fileName);
        
        NSData* outData=htNSDataFromWKData(data);
        if(outData){
            if ([outData writeToFile:outDir atomically:YES]) {
                HTAddXattrMDItemWhereFroms(outDir, [dic objectForKey:@"wherefroms"]);
            }
        }
    }
    CFRelease(info);
}


+ (NSPopover*)sharedSafariDownloadPopover
{
    Class safariDownloadsPopoverViewControllerClass=NSClassFromString(@"DownloadsPopoverViewController");
    if ([safariDownloadsPopoverViewControllerClass respondsToSelector:NSSelectorFromString(@"sharedController")]) {
        id viewCtl=objc_msgSend(safariDownloadsPopoverViewControllerClass, NSSelectorFromString(@"sharedController"));
        if ([viewCtl respondsToSelector:NSSelectorFromString(@"popover")]) {
            return objc_msgSend(viewCtl, NSSelectorFromString(@"popover"));
        }
    }
    return nil;
    
}


- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        _advSheetCtl=nil;
        [self loadFromStorage];

        SEL nameForPathSelector=[[NSFileManager defaultManager]stand_selectorForPathWithUniqueFilenameForPath];
        if (!nameForPathSelector)nameForPathSelector=@selector(stand_pathWithUniqueFilenameForPath:);
        /*
         1: DownloadsPath/file.name.download
         2: DownloadsPath/modPath/file.name
         */
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "NSFileManager", sel_getName(nameForPathSelector),
         KZRMethodInspection, call, sel,
         ^id (id slf, NSString *inStr){
             if(![[NSUserDefaults standardUserDefaults]boolForKey:kpClassifyDownloadFolderBasicEnabled]){
                 return call.as_id(slf, sel, inStr);
             }
             
             NSString* outputDir=inStr;
             NSString* rootDir=[inStr stringByDeletingLastPathComponent];
             NSString* defaultDir=[[[NSUserDefaults standardUserDefaults]stringForKey:@"DownloadsPath"]stringByStandardizingPath];
             if([defaultDir isEqualToString:rootDir]){
                 NSString* fileName=[inStr lastPathComponent];
                 NSString* filteredExpression=[self filteredExpressionForFileName:fileName url:nil];
                 
                 rootDir=[rootDir stringByAppendingPathComponent:filteredExpression];
                 
                 //フォルダ作成
                 BOOL isDirectory;
                 if(![[NSFileManager defaultManager] fileExistsAtPath:rootDir isDirectory:&isDirectory]){
                     isDirectory=[[NSFileManager defaultManager]createDirectoryAtPath:rootDir withIntermediateDirectories:YES attributes:nil error:nil];
                 }
                 
                 if(isDirectory){
                     outputDir=[rootDir stringByAppendingPathComponent:fileName];
                 }else{
                     outputDir=inStr;
                 }
             }
             
             NSString *result=call.as_id(slf, sel, outputDir);
             return result;
         });

    }
    
    return self;
}

- (void)modulesDidFinishLoading:(id)core
{
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kpDownloadMonitorMovesToConsolePanel]) {
        [self installDownloadMonitorViewToConsolePanel];
    }
}

- (void)dealloc
{

}

- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}



//from context menu
//no need check pref, already checked
- (void)actCopyImageToDownloadFolderMenu:(id)sender
{
    id webUserDataWrapper=[sender representedObject];
    void* apiObject=[webUserDataWrapper userData]; //struct APIObject
    uint32_t type=WKGetTypeID(apiObject);
    if(type==WKDictionaryGetTypeID()){ //8==TypeDictionary
        WKTypeRef frame=htWKDictionaryTypeRefForKey(apiObject, @"Frame");
        WKTypeRef imageURL=htWKDictionaryTypeRefForKey(apiObject, @"ImageURL");
        NSString* fileName=htWKDictionaryStringForKey(apiObject, @"ImageSuggestedFilename");
        if(!fileName || !frame){
            NSBeep();
            return;
        }
        WKTypeRef frameURL=WKFrameCopyURL(frame);
        if ([fileName hasSuffix:@".jpeg"]) {
            fileName=[[fileName stringByDeletingPathExtension]stringByAppendingPathExtension:@"jpg"];
        }
        if (frame && imageURL && frameURL) {
            NSString* imageURLStr=htNSStringFromWKURL(imageURL);
            NSString* frameURLStr=htNSStringFromWKURL(frameURL);
            NSArray* wherefroms=[NSArray arrayWithObjects:imageURLStr, frameURLStr, nil];
            NSDictionary* info=[[NSDictionary alloc]initWithObjectsAndKeys:wherefroms, @"wherefroms",
                               fileName, @"fileName", nil];
            
            WKFrameGetResourceData(frame, imageURL, (WKFrameGetResourceDataFunction)copyImageToDownloadFolderCallBack, (void*)CFBridgingRetain(info));
        }
    }
}

-(NSWindow*)advancedSettingSheet
{
    if (!_advSheetCtl) {
        _advSheetCtl=[[STClassifyDownloadAdvSheetCtl alloc]initWithWindowNibName:@"STClassifyDownloadAdvSheet"];
        _advSheetCtl.arrayBinder=self;
        [_advSheetCtl window];
    }
    return [_advSheetCtl window];
}


#pragma mark - IO

-(void)loadFromStorage
{
    self.basicExp=[[STCSafariStandCore si]objectForKey:kpClassifyDownloadFolderBasicExpression];
    if (!self.basicExp) {
        self.basicExp=@"%Y-%m-%d";
    }
    
    //searchItLaterStrings
    NSArray* savedArray=[[STCSafariStandCore si]objectForKey:kpClassifyDownloadFolderAdvancedRules];
    NSMutableArray* mutArray=[[NSMutableArray alloc]initWithCapacity:[savedArray count]+4];
    for (NSDictionary* data in savedArray) {
        NSMutableDictionary* qs=[[NSMutableDictionary alloc]initWithDictionary:data];
        if (qs) {
            [mutArray addObject:qs];
        }
    }
    self.advancedFilters=mutArray;

}


//url is not used currently
-(NSString*)expressionForRule:(NSDictionary*)rule fileName:(NSString*)fileName url:(id)url
{
    if([[rule objectForKey:@"use"]boolValue]!=YES)return nil;

    NSString* result=nil;
    NSString* ext=[fileName pathExtension];
    if ([[rule objectForKey:@"type"]isEqualToString:@"ext"] && [ext length]>0){
        
        NSArray* extAry=[[rule objectForKey:@"pattern"]stand_arrayWithStandardSeparation];
        if ([extAry containsObject:ext]) {
            result=[rule objectForKey:@"exp"];
        }
    }
    return result;
}

//url is not used currently
-(NSString*)filteredExpressionForFileName:(NSString*)fileName url:(id)url
{
    if ([fileName hasSuffix:@".download"])fileName=[fileName stringByDeletingPathExtension];
    NSString* ext=[fileName pathExtension];
    if(!ext || [ext length]<=0)ext=@"----";//need?
    
    NSString* basic=self.basicExp;
    if([basic length]<=0)basic=@"%Y-%m-%d";
    if([basic isEqualToString:@"/"])basic=@"";
    
    //advanced
    NSString* advPattern=nil;
    for (NSDictionary* rule in self.advancedFilters) {
        advPattern=[self expressionForRule:rule fileName:fileName url:url];
        if(advPattern)break;
    }
    if (advPattern) {
        if ([advPattern hasPrefix:@"@"]) {
            advPattern=[advPattern stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:basic];
        }
        basic=advPattern;
    }
    
    //{exp}
    basic=[basic stringByReplacingOccurrencesOfString:@"{exp}" withString:ext];
    
    //date
    NSString* filteredExpression=HTStringFromDateWithFormat([NSDate date], basic);

    return filteredExpression;

}

-(void)saveToStorage
{
    if(self.basicExp)[[STCSafariStandCore si]setObject:self.basicExp forKey:kpClassifyDownloadFolderBasicExpression];

    id data=self.advancedFilters;
    if(data)[[STCSafariStandCore si]setObject:data forKey:kpClassifyDownloadFolderAdvancedRules];
    
    [[STCSafariStandCore si]synchronize];
}


#pragma mark - DownloadMonitor

- (void)installDownloadMonitorViewToConsolePanel
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "AppController",
         "showDownloads:",
         KZRMethodInspection, call, sel,
         ^void (id slf, id sender){
             dispatch_async(dispatch_get_main_queue(), ^{
                 STConsolePanelModule* cp=[STCSafariStandCore mi:@"STConsolePanelModule"];
                 [cp showConsolePanelAndSelectTab:@"DownloadMonitor"];
             });
         });
        
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         kSafariBrowserWindowControllerCstr,
         "toggleDownloadsPopover:",
         KZRMethodInspection, call, sel,
         ^void (id slf, id sender){
             dispatch_async(dispatch_get_main_queue(), ^{
                 STConsolePanelModule* cp=[STCSafariStandCore mi:@"STConsolePanelModule"];
                 [cp showConsolePanelAndSelectTab:@"DownloadMonitor"];
             });
         });
    });
    
    
    STConsolePanelModule* consolePanelModule=[STCSafariStandCore mi:@"STConsolePanelModule"];
    
    NSString* imgPath=[[NSBundle bundleWithIdentifier:kSafariStandBundleID]pathForImageResource:@"STTBDownload"];
    NSImage* img=[[NSImage alloc]initWithContentsOfFile:imgPath];
    [img setTemplate:YES];
    //NSImage* img=STSafariBundleImageNamed(@"ToolbarDownloadsArrowTemplate");
    [consolePanelModule addPanelWithIdentifier:@"DownloadMonitor" title:@"Download Monitor" icon:img weight:20 loadHandler:^id{
        NSPopover* popover=[STSDownloadModule sharedSafariDownloadPopover];
        if (popover.shown) {
            [popover performClose:nil];
        }
        NSViewController* viewCtl=[popover contentViewController];
        return viewCtl;
    }];

}


@end
