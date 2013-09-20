//
//  STSDownloadModule.m
//  SafariStand


#import "SafariStand.h"
#import "STSDownloadModule.h"
#import "HTWebKit2Adapter.h"
#import "STClassifyDownloadAdvSheetCtl.h"


@implementation STSDownloadModule
@synthesize advancedFilters, basicExp;
/*
 1: DownloadsPath/file.name.download
 2: DownloadsPath/modPath/file.name
 
 */
IMP orig_pathWithUniqueFilenameForPath;
id ST_pathWithUniqueFilenameForPath(id self, SEL _cmd, NSString *inStr)
{
	if(![[NSUserDefaults standardUserDefaults]boolForKey:kpClassifyDownloadFolderBasicEnabled]){
        return orig_pathWithUniqueFilenameForPath(self, _cmd, inStr);
    }
    
    STSDownloadModule* dlModule=[STCSafariStandCore mi:@"STSDownloadModule"];
    
	NSString*   outputDir=inStr;
    NSString*   rootDir=[inStr stringByDeletingLastPathComponent];
    NSString*   defaultDir=[[[NSUserDefaults standardUserDefaults]stringForKey:@"DownloadsPath"]stringByStandardizingPath];
    if([defaultDir isEqualToString:rootDir]){
        NSString* fileName=[inStr lastPathComponent];
        
        NSString* filteredExpression=[dlModule filteredExpressionForFileName:fileName url:nil];

        rootDir=[rootDir stringByAppendingPathComponent:filteredExpression];
        
        //フォルダ作成
        BOOL	isDirectory;
        if(![[NSFileManager defaultManager] fileExistsAtPath:rootDir isDirectory:&isDirectory]){
            isDirectory=[[NSFileManager defaultManager]createDirectoryAtPath:rootDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        if(isDirectory)
            outputDir=[rootDir stringByAppendingPathComponent:fileName];
        else
            outputDir=inStr;
        
    }

    
    NSString *result=orig_pathWithUniqueFilenameForPath(self, _cmd, outputDir);
	return result;
}

//info is retained
void copyImageToDownloadFolderCallBack(void* data, void* error, NSDictionary* info)
{    
    NSAutoreleasePool* arp=[[NSAutoreleasePool alloc]init];
    NSString* fileName=[info objectForKey:@"fileName"];

    NSString* outDir=STSafariDownloadDestinationWithFileName(fileName);
    
    NSData* outData=htNSDataFromWKData(data);
    if(outData){
        if ([outData writeToFile:outDir atomically:YES]) {
            HTAddXattrMDItemWhereFroms(outDir, [info objectForKey:@"wherefroms"]);
        }
    }
    [arp drain];
    [info release];
}



- (id)initWithStand:(id)core
{
    self = [super initWithStand:core];
    if (self) {
        advSheetCtl=nil;
        [self loadFromStorage];

        orig_pathWithUniqueFilenameForPath = RMF(NSClassFromString(@"NSFileManager"),
                                @selector(_webkit_pathWithUniqueFilenameForPath:), ST_pathWithUniqueFilenameForPath);
    

    }
    return self;
}

- (void)dealloc
{
    [advSheetCtl release];
    [super dealloc];
}

- (void)prefValue:(NSString*)key changed:(id)value
{
    //if([key isEqualToString:])
}

//from context menu
//no need check pref, already checked
- (void)actCopyImageToDownloadFolderMenu:(id)sender
{
    if (![[NSFileManager defaultManager]respondsToSelector:@selector(_webkit_pathWithUniqueFilenameForPath:)]) {
        return;
    }
    
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
            
            WKFrameGetResourceData(frame, imageURL, (WKFrameGetResourceDataFunction)copyImageToDownloadFolderCallBack, info);
        }
    }
}

-(NSWindow*)advancedSettingSheet{
    if (!advSheetCtl) {
        advSheetCtl=[[STClassifyDownloadAdvSheetCtl alloc]initWithWindowNibName:@"STClassifyDownloadAdvSheet"];
        advSheetCtl.arrayBinder=self;
        [advSheetCtl window];
    }
    return [advSheetCtl window];
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
            [qs release];
        }
    }
    self.advancedFilters=mutArray;
    [mutArray release];
}


//url is not used currently
-(NSString*)expressionForRule:(NSDictionary*)rule fileName:(NSString*)fileName url:(id)url{
    if([[rule objectForKey:@"use"]boolValue]!=YES)return nil;

    NSString* result=nil;
    NSString* ext=[fileName pathExtension];
    if ([[rule objectForKey:@"type"]isEqualToString:@"ext"] && [ext length]>0){
        
        NSArray* extAry=[[rule objectForKey:@"pattern"]htArrayWithStandardSeparation];
        if ([extAry containsObject:ext]) {
            result=[rule objectForKey:@"exp"];
        }
    }
    return result;
}

//url is not used currently
-(NSString*)filteredExpressionForFileName:(NSString*)fileName url:(id)url{
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
    NSString*   filteredExpression=[[NSDate date]descriptionWithCalendarFormat:basic timeZone:nil locale:nil];

    return filteredExpression;

}

-(void)saveToStorage
{
    if(self.basicExp)[[STCSafariStandCore si]setObject:self.basicExp forKey:kpClassifyDownloadFolderBasicExpression];

    id data=self.advancedFilters;
    if(data)[[STCSafariStandCore si]setObject:data forKey:kpClassifyDownloadFolderAdvancedRules];
    
    [[STCSafariStandCore si]synchronize];
}

@end
