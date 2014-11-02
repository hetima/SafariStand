//
//  STCSimblLorder.m
//  SafariStand

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC
#endif


#import "SafariStand.h"
#import "STCSimblLorder.h"

@implementation STCSimblLorder

//SIMBL
+ (void)install
{
    [STCSafariStandCore si];
}

@end
