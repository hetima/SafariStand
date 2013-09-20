//
//  STCSafariStandCore+Toolbar.m
//  SafariStand


#import "SafariStand.h"


@implementation STCSafariStandCore (STCSafariStandCore_Toolbar)




-(void)registerToolbarIdentifier:(NSString*)identifier module:(id)obj
{
    [[self moduleForClassName:@"STSToolbarModule"]registerToolbarIdentifier:identifier module:obj];

}


@end
