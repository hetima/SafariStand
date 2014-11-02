//
//  STQuickSearchModule+Completion.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif

#import "SafariStand.h"
#import "STQuickSearchModule.h"
#import "STSafariConnect.h"

@interface STFakeURLCompletionMatch : NSObject

@property(nonatomic, strong) NSString* userVisibleURLString;
@property(nonatomic, strong) NSString* title;
@property(nonatomic, strong) NSString* originalURLString;
//@property(nonatomic, strong) id data;

@end


@implementation STFakeURLCompletionMatch

- (id)matchingStringWithUserTypedPrefix:(id)arg1
{
    return @"";
}

- (long long)matchLocation
{
    return NSNotFound;
}

- (id)parsecDomainIdentifier
{
    return @"tophit";
}

- (BOOL)isTopHit
{
    return YES;
}

@end


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


- (void)setupCompletionCtl
{

    KZRMETHOD_SWIZZLING_("WBSURLCompletionDatabase", "getBestMatchesForTypedString:topHits:matches:limit:",
                         void, call, sel)
    ^ (id slf, id str, id *topHits, id *matches, unsigned long long limit){
        call(slf, sel, str, topHits, matches, limit);
        
        NSDictionary* seedInfo=[quickSearchModule seedInfoForLocationText:str];
        NSString* searchStr=seedInfo[@"searchStr"];
        if ([searchStr length]>0) {
            HTQuerySeed* seed=seedInfo[@"seed"];
            if ([seed.method isEqualToString:@"GET"]) {
                NSURLRequest* req=[seed requestWithSearchString:searchStr];
                NSString* urlString=[[req URL]absoluteString];
                STFakeURLCompletionMatch* cmplMatch=[[STFakeURLCompletionMatch alloc]init];
                cmplMatch.userVisibleURLString=urlString;
                cmplMatch.originalURLString=urlString;
                NSString* title=[NSString stringWithFormat:@"🔍 %@: %@", seed.title, searchStr];
                cmplMatch.title=title;
                
                //seems no need
                //id fakeData=objc_msgSend(slf, @selector(fakeBookmarkMatchDataWithURLString:title:), urlString, title);
                //cmplMatch.data=fakeData;
                
                //array of WBSTopHitCompletionMatch
                NSMutableArray* ary=[[NSMutableArray alloc]init];
                [ary addObject:cmplMatch];

                if ([*topHits count]) {
                    [ary addObjectsFromArray:*topHits];
                }
                *topHits=ary;
            }
        }
        
    }_WITHBLOCK;
    
}


- (NSDictionary*)seedInfoForLocationText:(NSString*)inStr
{
    
    NSRange aRange=[inStr rangeOfString:@" "];
    if (aRange.length<=0) return nil;
    
    NSString* kwd=[inStr substringToIndex:aRange.location];
    //defaultは除外
    if ([kwd isEqualToString:kDefaultSeedShortcut]) return nil;
    
    HTQuerySeed* seed=[self querySeedForShortcut:kwd];
    if (!seed) return nil;
    
    NSString* searchStr=[inStr substringFromIndex:aRange.location+1];
    if (!searchStr) searchStr=@"";
    
    NSDictionary* result=@{@"seed":seed, @"searchStr":searchStr};
    
    return result;
}


@end
