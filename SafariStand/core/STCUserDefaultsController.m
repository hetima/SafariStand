//
//  STCUserDefaultsController.m
//  SafariStand


#import "SafariStand.h"
#import "STCUserDefaultsController.h"

@implementation STCUserDefaultsController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self=[super initWithCoder:coder];

    NSUserDefaults* ud=[STCSafariStandCore ud];
    ((void(*)(id, SEL, ...))objc_msgSend)(self, NSSelectorFromString(@"_setDefaults:"), ud);
    
    return self;
}

@end
