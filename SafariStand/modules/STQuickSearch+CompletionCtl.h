//
//  STQuickSearch+CompletionCtl.h
//  SafariStand


#import <Foundation/Foundation.h>
#import "STQuickSearch.h"

@interface STQuickSearch (STQuickSearch_CompletionCtl)
-(void)setupCompletionCtl;
-(HTQuerySeed*)seedForLocationText:(NSString*)inStr;
@end

