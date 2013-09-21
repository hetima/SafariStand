//
//  STCSafariStandCore+Toolbar.m
//  SafariStand

#if __has_feature(objc_arc)
#error This file must be compiled with -fno-objc_arc
#endif

#import "SafariStand.h"


@implementation STCSafariStandCore (STCSafariStandCore_Toolbar)




-(void)registerToolbarIdentifier:(NSString*)identifier module:(id)obj
{
    [[self moduleForClassName:@"STSToolbarModule"]registerToolbarIdentifier:identifier module:obj];

}


@end
