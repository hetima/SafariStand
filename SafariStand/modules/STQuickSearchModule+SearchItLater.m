//
//  STQuickSearchModule+SearchItLater.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

/*
 defaults delete com.apple.Safari Stand_QuerySeeds 
 */

#import "SafariStand.h"
#import "STSafariConnect.h"
#import "STQuickSearchModule.h"

#import "STConsolePanelModule.h"
#import "STSearchItLaterViewCtl.h"

@implementation STQuickSearchModule (STQuickSearchModule_SearchItLater)

-(void)installSearchItLaterViewToConsolePanel
{
    STConsolePanelModule* consolePanelModule=[STCSafariStandCore mi:@"STConsolePanelModule"];
    NSImage* img=[NSImage imageNamed:NSImageNameRevealFreestandingTemplate];

    [consolePanelModule addPanelWithIdentifier:@"SearchItLater" title:@"Search It Later" icon:img weight:1000 loadHandler:^id{
        NSViewController* viewCtl=[STSearchItLaterViewCtl viewCtl];
        return viewCtl;
    }];
}


-(NSMutableDictionary*)existingSearchItLaterForString:(NSString*)str
{
    for (NSMutableDictionary* sil in self.searchItLaterStrings) {
        NSString* val=[sil objectForKey:@"val"];
        if([val isEqualToString:str])return sil;
    }
    return  nil;
}


-(NSMutableDictionary*)searchItLaterForString:(NSString*)str
{
    NSMutableDictionary* sil=[self existingSearchItLaterForString:str];
    if(!sil){
        sil=[self addSearchItLaterString:str];
    }
    return sil;
}

-(void)actAddSearchItLaterMenu:(id)sender
{
    NSPasteboard* pb=[NSPasteboard pasteboardWithName:kSafariStandPBKey];
    NSString* selectedText=[[pb stringForType:NSStringPboardType]stand_moderatedStringWithin:0];
    
    if(selectedText)[self searchItLaterForString:selectedText];
}

-(void)actAddSearchItLaterWithFlagMenu:(id)sender
{
    NSPasteboard* pb=[NSPasteboard pasteboardWithName:kSafariStandPBKey];
    NSString* selectedText=[[pb stringForType:NSStringPboardType]stand_moderatedStringWithin:0];
    
    if(selectedText){
        NSMutableDictionary* sil=[self searchItLaterForString:selectedText];
        [sil setObject:[NSNumber numberWithBool:YES] forKey:@"flag"];
    }
}


-(NSMutableDictionary*)addSearchItLaterString:(NSString*)inStr
{
    NSDate* now=[NSDate date];
    NSNumber* count=[NSNumber numberWithInteger:0];
    inStr=[inStr stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    
    NSMutableDictionary* dic=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                              inStr, @"val", now, @"created", count, @"count", 
                              [NSNumber numberWithBool:NO], @"flag",
                              nil];
    if(dic){
        [self willChangeValueForKey:@"searchItLaterStrings"];
        [self.searchItLaterStrings addObject:dic];
        [self didChangeValueForKey:@"searchItLaterStrings"];

    }
    return dic;
}

-(void)removeSearchItLaterString:(NSString*)inStr
{
    NSMutableDictionary* dic=[self existingSearchItLaterForString:inStr];
    if(dic){
        [self willChangeValueForKey:@"searchItLaterStrings"];
        [self.searchItLaterStrings removeObject:dic];
        [self didChangeValueForKey:@"searchItLaterStrings"];
    }

}

@end