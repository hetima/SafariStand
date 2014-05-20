//
//  STQuickSearchModule+Completion.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STQuickSearchModule.h"
#import "STSafariConnect.h"


@implementation STQuickSearchModule (STQuickSearchModule_Completion)




BOOL isLikeURLString(NSString* inStr)
{
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



-(void)setupCompletionCtl
{
    //primeval impliments
    if ([NSClassFromString(kSafariBrowserWindowController) instancesRespondToSelector:@selector(goToToolbarLocation:)]) {
        
        //LocationTextField textDidChange:
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         "LocationTextField",
         "textDidChange:",
         KZRMethodInspection, call, sel,
         ^ (id slf, id obj)
        {
             //NSConcreteNotification name = NSTextDidChangeNotification; object = LocationFieldEditor
             HTQuerySeed* seed=[quickSearchModule seedForLocationText:[slf stringValue]];
             if(seed){
                 //LOG(@"%@", seed.title);
                 //objc_msgSend(slf, @selector(setShowsPageTitle:), YES);
                 //objc_msgSend(slf, @selector(setPageTitle:), seed.title);
                 //objc_msgSend(slf, @selector(setDetailString:), [NSString stringWithFormat:@"QuickSearch : ",seed.title]);
                 
             }else{
                 //if prev set
                 objc_msgSend(slf, @selector(setDetailString:), nil);
             }
             call.as_void(slf, sel, obj);
             if(seed){
                 objc_msgSend(slf, @selector(setDetailString:), [NSString stringWithFormat:@"QuickSearch : %@",seed.title]);
             }
             
             //seedForLocationText:
         });
        
        //kSafariBrowserWindowController goToToolbarLocation:
        KZRMETHOD_SWIZZLING_WITHBLOCK
        (
         kSafariBrowserWindowControllerCstr,
         "goToToolbarLocation:",
         KZRMethodInspection, call, sel,
         ^ (id slf, id obj)
        {
            NSString* locationString=[obj stringValue];
            HTQuerySeed* seed=[quickSearchModule seedForLocationText:locationString];
            if(seed){
                NSURLRequest* req=[seed requestWithLocationString:locationString];
                if(req){
                    //rangeOfString+1 は直前のrequestWithLocationString:で保証済み
                    NSString* searchStr=[locationString substringFromIndex:[locationString rangeOfString:@" "].location+1];
                    STSafariAddSearchStringHistory(searchStr);
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
                call.as_void(slf, sel, obj);
            }
            
         });

    }
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
