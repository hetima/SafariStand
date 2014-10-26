//
//  STCTabListViewCtl.m
//  SafariStand
//
//  Created by hetima on 2014/10/26.
//
//

#import "STCTabListViewCtl.h"
#import "STTabProxyController.h"

@interface STCTabListViewCtl ()

@end

@implementation STCTabListViewCtl

+ (STCTabListViewCtl*)viewCtl
{
    STCTabListViewCtl* result;
    result=[[STCTabListViewCtl alloc]initWithNibName:@"STCTabListViewCtl" bundle:
            [NSBundle bundleWithIdentifier:kSafariStandBundleID]];
    [result view];
    [result.aryCtl bind:@"contentArray" toObject:[STTabProxyController si] withKeyPath:@"allTabProxy" options:@{}];
    [result.aryCtl setFilterPredicate:[NSPredicate predicateWithFormat:@"hidden=0"]];
    
    return result;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
}

@end
