//
//  STQuickSearch+CompletionCtl.m
//  SafariStand


#import "SafariStand.h"
#import "STQuickSearch+CompletionCtl.h"
#import "STSafariConnect.h"


@implementation STQuickSearch (STQuickSearch_CompletionCtl)
//LocationTextField
IMP orig_textDidChange;
static void ST_textDidChange(id self, SEL _cmd, id obj){
	//NSConcreteNotification name = NSTextDidChangeNotification; object = LocationFieldEditor
    HTQuerySeed* seed=[quickSearchModule seedForLocationText:[self stringValue]];
    if(seed){
        //LOG(@"%@", seed.title);
        //objc_msgSend(self, @selector(setShowsPageTitle:), YES);
        //objc_msgSend(self, @selector(setPageTitle:), seed.title);
        //objc_msgSend(self, @selector(setDetailString:), [NSString stringWithFormat:@"QuickSearch : ",seed.title]);
        
    }else{
        //if prev set
        objc_msgSend(self, @selector(setDetailString:), nil);
    }
    orig_textDidChange(self, _cmd, obj);
    if(seed){
        objc_msgSend(self, @selector(setDetailString:), [NSString stringWithFormat:@"QuickSearch : %@",seed.title]);
    }
    
    
    //seedForLocationText:
}


BOOL isLikeURLString(NSString* inStr){
    NSInteger len=[inStr length];
    if(len<5)return NO;
//    if([inStr rangeOfString:@" "].location!=NSNotFound)return NO;
    if([inStr rangeOfString:@":/"].location!=NSNotFound
       || [inStr rangeOfString:@"."].location!=NSNotFound
       || [inStr hasPrefix:@"localhost"]){
        
        return YES;
    }
    return NO;
}

IMP orig_goToToolbarLocation;
void ST_goToToolbarLocation(id self, SEL _cmd, id obj){
    NSString* locationString=[obj stringValue];
    HTQuerySeed* seed=[quickSearchModule seedForLocationText:locationString];
    if(seed){
        NSURLRequest* req=[seed requestWithLocationString:locationString];
        if(req){
            //rangeOfString+1 は直前のrequestWithLocationString:で保証済み
            NSString* searchStr=[locationString substringFromIndex:[locationString rangeOfString:@" "].location+1];
            STAddSearchStringHistory(searchStr);
            STSafariGoToRequestWithPolicy(req, STSafariWindowPolicyFromCurrentEvent());
        }
        // FIXME: shortcut のみを打ち込むとreq==nilになってどこへも飛ばない
    }else{
        if([locationString hasPrefix:@"ttp://"]){
            [obj setStringValue:[@"h" stringByAppendingString:locationString]];
        }else if(!isLikeURLString(locationString)){
            //search engine
            [quickSearchModule sendDefaultQuerySeedWithSearchString:locationString  policy:STSafariWindowPolicyFromCurrentEvent()];
            return;
        }
        orig_goToToolbarLocation(self, _cmd, obj);
    }
    
}


-(void)setupCompletionCtl{
    orig_textDidChange = RMF(NSClassFromString(@"LocationTextField"),
                                              @selector(textDidChange:), ST_textDidChange);
    orig_goToToolbarLocation = RMF(NSClassFromString(kSafariBrowserWindowController),
                                                    @selector(goToLocationFieldURL:), ST_goToToolbarLocation);//was goToToolbarLocation:

}


-(HTQuerySeed*)seedForLocationText:(NSString*)inStr
{
    NSRange aRange=[inStr rangeOfString:@" "];
    if(aRange.length<=0)return nil;
    
    NSString* kwd=[inStr substringToIndex:aRange.location];
    //defaultはここでは除外
    if ([kwd isEqualToString:kDefaultSeedShortcut]) {
        return nil;
    }
    return [self querySeedForShortcut:kwd];
}


@end
